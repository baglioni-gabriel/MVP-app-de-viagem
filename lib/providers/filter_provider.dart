import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../models/filter_model.dart';
import '../models/post_model.dart';
import '../services/distance_service.dart';
import '../utils/geo_utils.dart';

// ─── Service singleton ───────────────────────────────────────────────

final distanceServiceProvider =
    Provider<DistanceService>((ref) => DistanceService());

// ─── Filter state ────────────────────────────────────────────────────

/// Manages the current [FilterCriteria] and applies client-side +
/// Distance Matrix API filtering to the raw feed.
///
/// Flow:
///   1. [updateCriteria] / [clearAll] — mutate filter state
///   2. [applyFilters] — run the full pipeline on a list of posts
///      (also called automatically from [updateCriteria] using the
///      last-known raw posts)
class FilterNotifier extends ChangeNotifier {
  final Ref _ref;

  FilterNotifier(this._ref);

  FilterCriteria _criteria = const FilterCriteria();
  FilterCriteria get criteria => _criteria;

  /// Cached travel times: postId → duration in minutes.
  /// Reset whenever the base location or travel mode changes.
  final Map<String, int> _travelTimesMinutes = {};
  Map<String, int> get travelTimesMinutes =>
      Map.unmodifiable(_travelTimesMinutes);

  /// Posts that passed both client-side and API filters.
  List<Post> _filteredPosts = [];
  List<Post> get filteredPosts => _filteredPosts;

  /// The last set of raw posts passed to [applyFilters].
  /// Used to re-run filters when criteria changes.
  List<Post> _lastRawPosts = [];

  bool _filtering = false;
  bool get filtering => _filtering;

  // ─── Criteria mutations ──────────────────────────────────────────

  /// Updates the filter criteria and automatically re-applies
  /// against the last-known raw posts.
  void updateCriteria(FilterCriteria newCriteria) {
    // Clear cached times when location/mode changes
    if (newCriteria.baseLocation != _criteria.baseLocation ||
        newCriteria.travelMode != _criteria.travelMode) {
      _travelTimesMinutes.clear();
    }
    _criteria = newCriteria;
    notifyListeners();

    // Re-apply with last known posts (fire-and-forget)
    if (_criteria.isActive && _lastRawPosts.isNotEmpty) {
      applyFilters(_lastRawPosts);
    } else if (!_criteria.isActive) {
      _filteredPosts = [];
      _travelTimesMinutes.clear();
      notifyListeners();
    }
  }

  void clearAll() {
    _criteria = const FilterCriteria();
    _travelTimesMinutes.clear();
    _filteredPosts = [];
    _lastRawPosts = [];
    notifyListeners();
  }

  // ─── Apply filters ───────────────────────────────────────────────

  /// Runs the full filter pipeline on [rawPosts]:
  ///
  /// 1. **Client-side date/availability filter** (instant, free)
  /// 2. **Haversine pre-filter** to discard obviously-too-far posts
  /// 3. **Distance Matrix API** batch call for remaining candidates
  /// 4. Keep posts within maxTravelTimeMinutes; sort by travel time
  Future<void> applyFilters(List<Post> rawPosts) async {
    _lastRawPosts = rawPosts;

    if (!_criteria.isActive) {
      _filteredPosts = [];
      _travelTimesMinutes.clear();
      notifyListeners();
      return;
    }

    _filtering = true;
    notifyListeners();

    try {
      // ── Step 1: client-side date & availability filter ──────────
      var candidates = _applyDateFilter(rawPosts);

      // ── Step 2+3: travel time filter (Haversine + API) ─────────
      if (_criteria.hasTravelFilter) {
        candidates = await _applyTravelTimeFilter(candidates);
      }

      _filteredPosts = candidates;
    } catch (_) {
      // On error, show unfiltered results
      _filteredPosts = rawPosts;
    }

    _filtering = false;
    notifyListeners();
  }

  // ─── Date / availability filter (client-side) ────────────────────

  List<Post> _applyDateFilter(List<Post> posts) {
    if (!_criteria.hasDateFilter) return posts;

    final start = _criteria.filterStartDate!;
    final end = _criteria.filterEndDate ?? start;

    return posts.where((post) {
      // Perennial events
      if (post.isPerennial) {
        if (!_criteria.includePerennial) return false;

        // Even perennial posts can have unavailable days.
        // Check if ALL days in the filter range fall on unavailable days.
        if (post.unavailableDays.isNotEmpty) {
          return !_allDaysUnavailable(start, end, post.unavailableDays);
        }
        return true;
      }

      // Non-perennial: check date overlap
      //   post range: [startDateTime, endDateTime]
      //   filter range: [start, end]
      //   Overlap: post.start <= end && post.end >= start
      final postEnd = post.endDateTime ?? post.startDateTime;
      final hasOverlap = !post.startDateTime.isAfter(end) &&
          !postEnd.isBefore(start);

      if (!hasOverlap) return false;

      // Check unavailable days within the overlap period
      if (post.unavailableDays.isNotEmpty) {
        final overlapStart =
            post.startDateTime.isAfter(start) ? post.startDateTime : start;
        final overlapEnd = postEnd.isBefore(end) ? postEnd : end;
        return !_allDaysUnavailable(
            overlapStart, overlapEnd, post.unavailableDays);
      }

      return true;
    }).toList();
  }

  /// Returns `true` when every day in [start..end] falls on an unavailable
  /// weekday. This means the post has zero available days in the range.
  bool _allDaysUnavailable(
      DateTime start, DateTime end, List<String> unavailableDays) {
    final unavailableSet =
        unavailableDays.map((d) => d.toLowerCase()).toSet();

    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      final dayName = _weekdayName(current.weekday).toLowerCase();
      if (!unavailableSet.contains(dayName)) return false;
      current = current.add(const Duration(days: 1));
    }
    return true;
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  // ─── Travel time filter (Haversine + Distance Matrix API) ────────

  Future<List<Post>> _applyTravelTimeFilter(List<Post> posts) async {
    final origin = _criteria.baseLocation!;
    final maxMinutes = _criteria.maxTravelTimeMinutes!;
    final mode = _criteria.travelMode;

    // Haversine pre-filter — generous upper-bound speed
    final avgSpeed = switch (mode) {
      TravelMode.driving => 130.0,
      TravelMode.transit => 80.0,
      TravelMode.walking => 6.0,
    };

    final maxKm = GeoUtils.maxReachableKm(
      travelTimeMinutes: maxMinutes,
      avgSpeedKmh: avgSpeed,
    );

    // Filter by straight-line distance and split into cached vs. uncached
    final candidateIndices = <int>[];
    final uncachedPosts = <Post>[];
    final uncachedGeoPoints = <GeoPoint>[];
    // Maps uncached index → candidate index
    final uncachedToCandidate = <int, int>{};

    for (var i = 0; i < posts.length; i++) {
      final post = posts[i];
      final km = GeoUtils.haversineKm(
        origin.latitude,
        origin.longitude,
        post.location.latitude,
        post.location.longitude,
      );

      if (km > maxKm) continue; // obviously too far

      candidateIndices.add(i);

      // Check cache
      if (_travelTimesMinutes.containsKey(post.id)) continue;

      uncachedToCandidate[uncachedPosts.length] = i;
      uncachedPosts.add(post);
      uncachedGeoPoints.add(post.location);
    }

    // Batch Distance Matrix call for uncached posts
    if (uncachedGeoPoints.isNotEmpty) {
      final service = _ref.read(distanceServiceProvider);
      final results = await service.batchGetTravelTimes(
          origin, uncachedGeoPoints, mode);

      for (final entry in results.entries) {
        final postIndex = uncachedToCandidate[entry.key];
        if (postIndex == null) continue;
        final post = posts[postIndex];
        _travelTimesMinutes[post.id] =
            (entry.value.durationSeconds / 60).ceil();
      }
    }

    // Build result list: only posts within maxTravelTimeMinutes
    final result = <Post>[];
    for (final idx in candidateIndices) {
      final post = posts[idx];
      final minutes = _travelTimesMinutes[post.id];
      if (minutes != null && minutes <= maxMinutes) {
        result.add(post);
      }
    }

    // Sort by travel time ascending
    result.sort((a, b) {
      final aMin = _travelTimesMinutes[a.id] ?? 999999;
      final bMin = _travelTimesMinutes[b.id] ?? 999999;
      return aMin.compareTo(bMin);
    });

    return result;
  }
}

/// Riverpod provider for [FilterNotifier].
final filterProvider = ChangeNotifierProvider<FilterNotifier>((ref) {
  return FilterNotifier(ref);
});
