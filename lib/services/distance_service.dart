import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../config/constants.dart';

/// Result of a single Distance Matrix lookup.
class TravelTimeResult {
  /// Duration in seconds.
  final int durationSeconds;

  /// Human-readable duration string from the API (e.g. "23 mins").
  final String durationText;

  const TravelTimeResult({
    required this.durationSeconds,
    required this.durationText,
  });
}

/// Wraps the Google Distance Matrix API.
///
/// Provides both single-destination and batch lookups.
/// Batch calls are capped at [AppConstants.maxDistanceMatrixDestinations]
/// destinations per request (API limit = 25).
class DistanceService {
  String get _key => AppConstants.googleMapsApiKey;

  // ─── Single destination ──────────────────────────────────────────────

  /// Returns the travel time in **seconds** from [origin] to [dest]
  /// for the given [mode], or `null` if the route is not found.
  Future<TravelTimeResult?> getTravelTime(
    GeoPoint origin,
    GeoPoint dest,
    TravelMode mode,
  ) async {
    final results = await batchGetTravelTimes(origin, [dest], mode);
    return results.values.firstOrNull;
  }

  // ─── Batch destinations ──────────────────────────────────────────────

  /// Queries travel times from [origin] to multiple [destinations].
  ///
  /// Returns a map of `index → TravelTimeResult` for each reachable
  /// destination. If the API returns `ZERO_RESULTS` or an error for
  /// a particular destination, it is omitted from the map.
  ///
  /// Automatically chunks requests into batches of
  /// [AppConstants.maxDistanceMatrixDestinations].
  Future<Map<int, TravelTimeResult>> batchGetTravelTimes(
    GeoPoint origin,
    List<GeoPoint> destinations,
    TravelMode mode,
  ) async {
    if (_key.isEmpty || destinations.isEmpty) return {};

    final results = <int, TravelTimeResult>{};
    final chunkSize = AppConstants.maxDistanceMatrixDestinations;

    for (var offset = 0; offset < destinations.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, destinations.length);
      final chunk = destinations.sublist(offset, end);

      final destParam =
          chunk.map((g) => '${g.latitude},${g.longitude}').join('|');

      final uri = Uri.parse(AppConstants.distanceMatrixBaseUrl)
          .replace(queryParameters: {
        'origins': '${origin.latitude},${origin.longitude}',
        'destinations': destParam,
        'mode': mode.toApiString(),
        'key': _key,
      });

      try {
        final resp = await http.get(uri);
        if (resp.statusCode != 200) continue;

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        if (json['status'] != 'OK') continue;

        final rows = json['rows'] as List?;
        if (rows == null || rows.isEmpty) continue;

        final elements = rows.first['elements'] as List;
        for (var i = 0; i < elements.length; i++) {
          final el = elements[i] as Map<String, dynamic>;
          if (el['status'] != 'OK') continue;

          final duration = el['duration'] as Map<String, dynamic>;
          results[offset + i] = TravelTimeResult(
            durationSeconds: duration['value'] as int,
            durationText: duration['text'] as String,
          );
        }
      } catch (_) {
        // Swallow network errors — filtered posts simply won't get times
      }
    }

    return results;
  }
}
