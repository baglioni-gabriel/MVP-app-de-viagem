import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Represents a user in the system (both Traveler and Business).
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.fromFirestore(data['role'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
