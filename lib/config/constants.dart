import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application-wide constants and configuration values.
class AppConstants {
  AppConstants._();

  // ─── API Keys (loaded from .env) ──────────────────────────────────
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ─── Firestore collection names ───────────────────────────────────
  static const String usersCollection = 'users';
  static const String businessPagesCollection = 'businessPages';
  static const String postsCollection = 'posts';
  static const String likesSubcollection = 'likes';
  static const String commentsSubcollection = 'comments';

  // ─── Google Maps defaults ─────────────────────────────────────────
  static const double defaultLat = -23.5505; // São Paulo
  static const double defaultLng = -46.6333;
  static const int defaultMapZoom = 12;

  // ─── Distance Matrix ──────────────────────────────────────────────
  static const int maxDistanceMatrixDestinations = 25;
  static const String distanceMatrixBaseUrl =
      'https://maps.googleapis.com/maps/api/distancematrix/json';

  // ─── Image constraints ────────────────────────────────────────────
  static const double maxImageWidth = 1080;
  static const double maxImageHeight = 1080;
  static const int imageQuality = 85;

  // ─── Pagination ───────────────────────────────────────────────────
  static const int feedPageSize = 15;
}

/// User roles used throughout the app.
enum UserRole {
  traveler,
  business;

  /// Returns the Firestore string representation.
  String toFirestore() => name;

  /// Parses a Firestore string back to enum.
  static UserRole fromFirestore(String value) =>
      UserRole.values.firstWhere((e) => e.name == value);
}

/// Travel mode options for Distance Matrix filtering.
enum TravelMode {
  driving,
  walking,
  transit;

  String toApiString() => name;
}

/// Days of the week — used for the unavailableDays field.
enum Weekday {
  monday('Monday'),
  tuesday('Tuesday'),
  wednesday('Wednesday'),
  thursday('Thursday'),
  friday('Friday'),
  saturday('Saturday'),
  sunday('Sunday');

  const Weekday(this.label);
  final String label;
}
