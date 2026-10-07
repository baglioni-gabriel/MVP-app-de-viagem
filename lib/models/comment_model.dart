import 'package:cloud_firestore/cloud_firestore.dart';

/// A comment on a Post.
class Comment {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      authorUid: data['authorUid'] as String,
      authorName: data['authorName'] as String,
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
