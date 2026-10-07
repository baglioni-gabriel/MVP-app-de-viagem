import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';

/// Lightweight data class for a Places Autocomplete suggestion.
class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}

/// Detail returned by the Places Details API (coordinates + formatted address).
class PlaceDetail {
  final String formattedAddress;
  final double lat;
  final double lng;

  const PlaceDetail({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}

/// Wraps the Google Maps Places and Geocoding REST APIs.
///
/// We use HTTP rather than the native SDK plugins so we can
/// keep the implementation simple, cross-platform, and independent
/// of the map-widget dependency.
class LocationService {
  static const _placesAutoBase =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _placesDetailBase =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeBase =
      'https://maps.googleapis.com/maps/api/geocode/json';

  String get _key => AppConstants.googleMapsApiKey;

  // ─── Places Autocomplete ────────────────────────────────────────────

  /// Returns a list of place suggestions matching [query].
  ///
  /// An empty list is returned when the API key is missing or the
  /// query is too short (< 3 characters).
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (_key.isEmpty || query.trim().length < 3) return [];

    final uri = Uri.parse(_placesAutoBase).replace(queryParameters: {
      'input': query.trim(),
      'key': _key,
      'types': 'geocode|establishment',
    });

    final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final predictions = json['predictions'] as List? ?? [];

    return predictions.map((p) {
      return PlaceSuggestion(
        placeId: p['place_id'] as String,
        description: p['description'] as String,
      );
    }).toList();
  }

  // ─── Place Details ──────────────────────────────────────────────────

  /// Fetches coordinates and a formatted address for [placeId].
  Future<PlaceDetail?> getPlaceDetails(String placeId) async {
    if (_key.isEmpty) return null;

    final uri = Uri.parse(_placesDetailBase).replace(queryParameters: {
      'place_id': placeId,
      'key': _key,
      'fields': 'formatted_address,geometry',
    });

    final resp = await http.get(uri);
    if (resp.statusCode != 200) return null;

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final geo = result['geometry']?['location'];
    if (geo == null) return null;

    return PlaceDetail(
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: (geo['lat'] as num).toDouble(),
      lng: (geo['lng'] as num).toDouble(),
    );
  }

  // ─── Reverse Geocode ────────────────────────────────────────────────

  /// Converts latitude/longitude into a human-readable address string.
  Future<String> reverseGeocode(double lat, double lng) async {
    if (_key.isEmpty) return '$lat, $lng';

    final uri = Uri.parse(_geocodeBase).replace(queryParameters: {
      'latlng': '$lat,$lng',
      'key': _key,
    });

    final resp = await http.get(uri);
    if (resp.statusCode != 200) return '$lat, $lng';

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = json['results'] as List? ?? [];
    if (results.isEmpty) return '$lat, $lng';

    return results.first['formatted_address'] as String? ?? '$lat, $lng';
  }
}
