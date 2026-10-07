import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// A Post (Experience / Event) in the travel social network.
///
/// If [endDateTime] is `null`, the post is considered "Perennial" —
/// an ongoing, indefinite event/service that never expires.
class Post {
  final String id;
  final String authorUid;
  final String authorRole;
  final String? businessPageId;
  final String title;
  final String description;
  final String imageUrl;
  final String address;
  final GeoPoint location;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final bool isPerennial;
  final String operatingHours;
  final List<String> unavailableDays;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.authorUid,
    required this.authorRole,
    this.businessPageId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.location,
    required this.startDateTime,
    this.endDateTime,
    required this.isPerennial,
    required this.operatingHours,
    this.unavailableDays = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final endTs = data['endDateTime'] as Timestamp?;
    return Post(
      id: doc.id,
      authorUid: data['authorUid'] as String,
      authorRole: data['authorRole'] as String,
      businessPageId: data['businessPageId'] as String?,
      title: data['title'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String,
      address: data['address'] as String,
      location: data['location'] as GeoPoint,
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: endTs?.toDate(),
      isPerennial: data['isPerennial'] as bool? ?? (endTs == null),
      operatingHours: data['operatingHours'] as String? ?? '',
      unavailableDays: List<String>.from(data['unavailableDays'] ?? []),
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorRole': authorRole,
      'businessPageId': businessPageId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'location': location,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime':
          endDateTime != null ? Timestamp.fromDate(endDateTime!) : null,
      'isPerennial': isPerennial,
      'operatingHours': operatingHours,
      'unavailableDays': unavailableDays,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convenience factory: automatically derives [isPerennial] from [endDateTime].
  factory Post.create({
    required String id,
    required String authorUid,
    required UserRole role,
    String? businessPageId,
    required String title,
    required String description,
    required String imageUrl,
    required String address,
    required GeoPoint location,
    required DateTime startDateTime,
    DateTime? endDateTime,
    required String operatingHours,
    List<String> unavailableDays = const [],
  }) {
    return Post(
      id: id,
      authorUid: authorUid,
      authorRole: role.toFirestore(),
      businessPageId: businessPageId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      address: address,
      location: location,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isPerennial: endDateTime == null,
      operatingHours: operatingHours,
      unavailableDays: unavailableDays,
      createdAt: DateTime.now(),
    );
  }
}
