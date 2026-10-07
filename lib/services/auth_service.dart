import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/constants.dart';
import '../models/user_model.dart';

/// Wraps [FirebaseAuth] and Firestore user-document operations.
///
/// All auth-related logic is centralised here so that providers
/// and screens never call Firebase directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Auth state ─────────────────────────────────────────────────────

  /// Real-time stream of the currently signed-in Firebase user (or `null`).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  // ─── Sign up ────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth account.
  ///
  /// Does **not** write the Firestore user document yet — that happens
  /// in [saveUserRole] after the role-selection step.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ─── Sign in ────────────────────────────────────────────────────────

  /// Signs in with email + password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ─── Sign out ───────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ─── Firestore user document ────────────────────────────────────────

  /// Creates (or overwrites) the `/users/{uid}` document with the
  /// chosen [role] and initial profile data.
  ///
  /// Called once from the role-selection screen right after sign-up.
  Future<void> saveUserRole({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
  }) async {
    final now = DateTime.now();
    final user = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      createdAt: now,
      updatedAt: now,
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toFirestore());
  }

  /// Fetches the Firestore user document for [uid].
  ///
  /// Returns `null` if the document doesn't exist yet (i.e. the user
  /// hasn't completed role selection).
  Future<AppUser?> getAppUser(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Streams the Firestore user document so the UI reacts to profile
  /// changes in real-time.
  Stream<AppUser?> streamAppUser(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? AppUser.fromFirestore(snap) : null);
  }
}
