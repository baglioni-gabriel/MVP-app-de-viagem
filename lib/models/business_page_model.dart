import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Business Page with extended details.
class BusinessPage {
  final String id;
  final String ownerUid;
  final String businessName;
  final String description;
  final String category;
  final String address;
  final GeoPoint location;
  final String? phoneNumber;
  final String? website;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessPage({
    required this.id,
    required this.ownerUid,
    required this.businessName,
    required this.description,
    required this.category,
    required this.address,
    required this.location,
    this.phoneNumber,
    this.website,
    this.photoUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessPage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessPage(
      id: doc.id,
      ownerUid: data['ownerUid'] as String,
      businessName: data['businessName'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      address: data['address'] as String,
      location: data['location'] as GeoPoint,
      phoneNumber: data['phoneNumber'] as String?,
      website: data['website'] as String?,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'businessName': businessName,
      'description': description,
      'category': category,
      'address': address,
      'location': location,
      'phoneNumber': phoneNumber,
      'website': website,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BusinessPage copyWith({
    String? businessName,
    String? description,
    String? category,
    String? address,
    GeoPoint? location,
    String? phoneNumber,
    String? website,
    List<String>? photoUrls,
  }) {
    return BusinessPage(
      id: id,
      ownerUid: ownerUid,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
