import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

// ─── Singleton service instance ──────────────────────────────────────

/// Provides the [AuthService] singleton across the app.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ─── Firebase Auth state ─────────────────────────────────────────────

/// Emits the raw Firebase [User?] every time auth state changes
/// (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ─── Firestore AppUser document ──────────────────────────────────────

/// Once we know the Firebase user's UID, this provider streams the
/// corresponding Firestore `/users/{uid}` document.
///
/// • Returns `null` while the user hasn't completed role selection.
/// • Emits a new [AppUser] whenever the document is updated.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return ref.watch(authServiceProvider).streamAppUser(firebaseUser.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// ─── Derived convenience providers ───────────────────────────────────

/// `true` when a Firebase user is signed in (regardless of role).
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// `true` when the signed-in user already has a Firestore user document
/// (i.e. has completed role selection).
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(appUserProvider).valueOrNull != null;
});
