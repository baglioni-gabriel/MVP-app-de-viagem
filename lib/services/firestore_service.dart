import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constants.dart';
import '../models/business_page_model.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// Generic Firestore CRUD helpers + typed methods for users,
/// business pages, posts, likes, and comments.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ──────────────────────────────────────────────────────────

  /// Updates specific fields on the user document (merge).
  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    data['updatedAt'] = Timestamp.now();
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  /// Fetches a single user document.
  Future<AppUser?> getUser(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  // ─── Business Pages ─────────────────────────────────────────────────

  Future<String> createBusinessPage(BusinessPage page) async {
    final docRef = _db
        .collection(AppConstants.businessPagesCollection)
        .doc();
    final data = page.toFirestore();
    data['createdAt'] = Timestamp.now();
    data['updatedAt'] = Timestamp.now();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateBusinessPage(
      String pageId, Map<String, dynamic> data) {
    data['updatedAt'] = Timestamp.now();
    return _db
        .collection(AppConstants.businessPagesCollection)
        .doc(pageId)
        .update(data);
  }

  Future<BusinessPage?> getBusinessPage(String pageId) async {
    final doc = await _db
        .collection(AppConstants.businessPagesCollection)
        .doc(pageId)
        .get();
    if (!doc.exists) return null;
    return BusinessPage.fromFirestore(doc);
  }

  Stream<BusinessPage?> streamBusinessPage(String pageId) {
    return _db
        .collection(AppConstants.businessPagesCollection)
        .doc(pageId)
        .snapshots()
        .map((s) => s.exists ? BusinessPage.fromFirestore(s) : null);
  }

  Future<BusinessPage?> getBusinessPageByOwner(String uid) async {
    final query = await _db
        .collection(AppConstants.businessPagesCollection)
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return BusinessPage.fromFirestore(query.docs.first);
  }

  Stream<BusinessPage?> streamBusinessPageByOwner(String uid) {
    return _db
        .collection(AppConstants.businessPagesCollection)
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : BusinessPage.fromFirestore(snap.docs.first));
  }

  // ─── Posts ──────────────────────────────────────────────────────────

  Future<String> createPost(Post post) async {
    final docRef =
        _db.collection(AppConstants.postsCollection).doc();
    final data = post.toFirestore();
    data['createdAt'] = Timestamp.now();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) {
    return _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .update(data);
  }

  Future<Post?> getPost(String postId) async {
    final doc =
        await _db.collection(AppConstants.postsCollection).doc(postId).get();
    if (!doc.exists) return null;
    return Post.fromFirestore(doc);
  }

  Stream<Post?> streamPost(String postId) {
    return _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .snapshots()
        .map((s) => s.exists ? Post.fromFirestore(s) : null);
  }

  // ─── Feed pagination ───────────────────────────────────────────────

  /// Fetches the first page of posts (newest first).
  Future<List<Post>> fetchFeedPage({
    int limit = AppConstants.feedPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    return snap.docs.map((d) => Post.fromFirestore(d)).toList();
  }

  /// Returns the raw [DocumentSnapshot] for cursor-based pagination.
  Future<QuerySnapshot> fetchFeedPageRaw({
    int limit = AppConstants.feedPageSize,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  // ─── Likes (sub-collection: posts/{postId}/likes/{uid}) ────────────

  /// Checks if [uid] has already liked [postId].
  Future<bool> hasUserLiked(String postId, String uid) async {
    final doc = await _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.likesSubcollection)
        .doc(uid)
        .get();
    return doc.exists;
  }

  /// Streams whether [uid] has liked [postId].
  Stream<bool> streamHasUserLiked(String postId, String uid) {
    return _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.likesSubcollection)
        .doc(uid)
        .snapshots()
        .map((s) => s.exists);
  }

  /// Toggles a like using a **batch write** for atomicity.
  ///
  /// If the like doc exists → deletes it and decrements `likesCount`.
  /// If it doesn't exist → creates it and increments `likesCount`.
  /// Both operations are committed in a single atomic batch.
  Future<void> toggleLike(String postId, String uid) async {
    final likeRef = _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.likesSubcollection)
        .doc(uid);
    final postRef = _db.collection(AppConstants.postsCollection).doc(postId);

    final likeDoc = await likeRef.get();
    final batch = _db.batch();

    if (likeDoc.exists) {
      batch.delete(likeRef);
      batch.update(postRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {'createdAt': Timestamp.now()});
      batch.update(postRef, {'likesCount': FieldValue.increment(1)});
    }

    await batch.commit();
  }

  // ─── Comments (sub-collection: posts/{postId}/comments) ────────────

  /// Streams comments on [postId], oldest first (natural reading order).
  Stream<List<Comment>> streamComments(String postId) {
    return _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  /// Adds a comment and increments `commentsCount` in a single
  /// **batch write** for atomicity.
  Future<void> addComment(String postId, Comment comment) async {
    final commRef = _db
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection)
        .doc();
    final postRef = _db.collection(AppConstants.postsCollection).doc(postId);

    final batch = _db.batch();
    batch.set(commRef, comment.toFirestore());
    batch.update(postRef, {'commentsCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ─── Generic helpers ────────────────────────────────────────────────

  Future<void> deleteDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).delete();
  }
}
