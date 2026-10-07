import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../providers/profile_provider.dart';

// ─── Firebase UID (independent of auth_provider to avoid circular deps) ──

final _firebaseAuthUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
});

/// Helper — current UID for like-state checks.
final authUidForFeedProvider = Provider<String?>((ref) {
  return ref.watch(_firebaseAuthUidProvider).valueOrNull;
});

// ─── Feed notifier (cursor-based pagination) ─────────────────────────

/// Manages the paginated home feed.
///
/// Holds the current list of [Post]s and a Firestore cursor for
/// "load more" functionality.
class FeedNotifier extends ChangeNotifier {
  final Ref _ref;

  FeedNotifier(this._ref);

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loading = false;
  bool get loading => _loading;

  /// Fetches the first page, replacing any existing data (pull-to-refresh).
  Future<void> refresh() async {
    _lastDoc = null;
    _hasMore = true;
    _loading = true;
    notifyListeners();

    try {
      final snap = await _ref
          .read(firestoreServiceProvider)
          .fetchFeedPageRaw(limit: AppConstants.feedPageSize);

      _posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.length >= AppConstants.feedPageSize;
    } catch (_) {
      // Keep existing data on error
    }

    _loading = false;
    notifyListeners();
  }

  /// Appends the next page.
  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    notifyListeners();

    try {
      final snap = await _ref
          .read(firestoreServiceProvider)
          .fetchFeedPageRaw(
              limit: AppConstants.feedPageSize, startAfter: _lastDoc);

      final newPosts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      _posts = [..._posts, ...newPosts];
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
      _hasMore = snap.docs.length >= AppConstants.feedPageSize;
    } catch (_) {
      // Keep existing data
    }

    _loading = false;
    notifyListeners();
  }
}

/// Provider for [FeedNotifier] — auto-disposes so the feed is
/// re-fetched when the user signs out and back in.
final feedProvider = ChangeNotifierProvider<FeedNotifier>((ref) {
  final notifier = FeedNotifier(ref);
  // Kick off initial load
  notifier.refresh();
  return notifier;
});

// ─── Single post stream ──────────────────────────────────────────────

/// Streams a single post by ID (for the detail screen).
final postByIdProvider =
    StreamProvider.family<Post?, String>((ref, postId) {
  return ref.watch(firestoreServiceProvider).streamPost(postId);
});

// ─── Like state ──────────────────────────────────────────────────────

/// Streams whether the current user has liked a post.
final hasLikedProvider =
    StreamProvider.family<bool, String>((ref, postId) {
  final uid = ref.watch(authUidForFeedProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(firestoreServiceProvider).streamHasUserLiked(postId, uid);
});

// ─── Comments ────────────────────────────────────────────────────────

/// Streams comments on a post.
final commentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(firestoreServiceProvider).streamComments(postId);
});
