import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business_page_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// ─── Service singletons ──────────────────────────────────────────────

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

// ─── Business page for the current user ──────────────────────────────

/// Streams the [BusinessPage] owned by the currently signed-in user.
///
/// • Returns `null` if the user is not a Business or hasn't created a page yet.
/// • Automatically re-fetches when the underlying auth state changes.
final myBusinessPageProvider = StreamProvider<BusinessPage?>((ref) {
  final appUser = ref.watch(appUserProvider).valueOrNull;
  if (appUser == null) return Stream.value(null);

  return ref
      .watch(firestoreServiceProvider)
      .streamBusinessPageByOwner(appUser.uid);
});

// ─── Business page by ID (for viewing other users' pages) ────────────

/// Family provider to stream any business page by its document ID.
final businessPageByIdProvider =
    StreamProvider.family<BusinessPage?, String>((ref, pageId) {
  return ref.watch(firestoreServiceProvider).streamBusinessPage(pageId);
});
