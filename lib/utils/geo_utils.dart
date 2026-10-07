import 'dart:math';

/// Geo-spatial utility functions.
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Calculates the Haversine distance in kilometres between two points.
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Estimates the maximum reachable distance (km) for a given travel time
  /// and average speed. Used as a generous pre-filter before calling
  /// the Distance Matrix API.
  static double maxReachableKm({
    required int travelTimeMinutes,
    double avgSpeedKmh = 130.0, // generous upper-bound for driving
  }) {
    return (travelTimeMinutes / 60.0) * avgSpeedKmh;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}
