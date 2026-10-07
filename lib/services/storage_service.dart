import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../config/constants.dart';

/// Handles all Firebase Storage uploads (profile photos, post images,
/// business gallery photos).
///
/// File paths follow the convention:
///   `users/{uid}/profile.jpg`
///   `posts/{postId}/image.jpg`
///   `businessPages/{pageId}/gallery/{filename}`
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Profile photo ──────────────────────────────────────────────────

  /// Uploads a profile photo for [uid] and returns the download URL.
  ///
  /// Resizing should be done before calling this (via image_picker's
  /// `maxWidth` / `maxHeight` params).
  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref('users/$uid/profile.jpg');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snap = await task;
    return snap.ref.getDownloadURL();
  }

  // ─── Post image ─────────────────────────────────────────────────────

  /// Uploads the primary image for a post.
  Future<String> uploadPostImage({
    required String postId,
    required File file,
  }) async {
    final ref = _storage.ref('posts/$postId/image.jpg');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snap = await task;
    return snap.ref.getDownloadURL();
  }

  // ─── Business gallery ──────────────────────────────────────────────

  /// Uploads a single gallery photo for a business page.
  ///
  /// Each photo gets a unique name based on the current timestamp.
  Future<String> uploadBusinessGalleryPhoto({
    required String pageId,
    required File file,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('businessPages/$pageId/gallery/$name');
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snap = await task;
    return snap.ref.getDownloadURL();
  }

  /// Uploads multiple gallery photos and returns all download URLs.
  Future<List<String>> uploadBusinessGalleryPhotos({
    required String pageId,
    required List<File> files,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadBusinessGalleryPhoto(pageId: pageId, file: file);
      urls.add(url);
    }
    return urls;
  }

  // ─── Delete ─────────────────────────────────────────────────────────

  /// Deletes a file from Storage given its download URL.
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Silently fail — file may already be deleted.
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Maximum allowed image dimensions (used by callers before upload).
  static double get maxWidth => AppConstants.maxImageWidth;
  static double get maxHeight => AppConstants.maxImageHeight;
  static int get quality => AppConstants.imageQuality;
}
