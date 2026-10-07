import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Sentinel used by [FilterCriteria.copyWith] to explicitly clear
/// a nullable field (as opposed to leaving it unchanged).
class _Absent {
  const _Absent();
}

const _absent = _Absent();

/// Filter criteria applied to the Home Feed.
class FilterCriteria {
  /// Base location from which travel time is measured.
  final GeoPoint? baseLocation;

  /// Human-readable label for [baseLocation] (shown in the filter bar).
  final String? baseLocationLabel;

  /// Maximum travel time in minutes.
  final int? maxTravelTimeMinutes;

  /// Travel mode (driving, walking, transit).
  final TravelMode travelMode;

  /// Start of the date-range filter.
  final DateTime? filterStartDate;

  /// End of the date-range filter.
  final DateTime? filterEndDate;

  /// Whether to include perennial (indefinite) posts when date-filtering.
  final bool includePerennial;

  const FilterCriteria({
    this.baseLocation,
    this.baseLocationLabel,
    this.maxTravelTimeMinutes,
    this.travelMode = TravelMode.driving,
    this.filterStartDate,
    this.filterEndDate,
    this.includePerennial = true,
  });

  /// Returns `true` when any filter is actively set.
  bool get isActive =>
      baseLocation != null ||
      maxTravelTimeMinutes != null ||
      filterStartDate != null ||
      filterEndDate != null;

  /// `true` when the travel-time filter (base + max time) is fully set.
  bool get hasTravelFilter =>
      baseLocation != null && maxTravelTimeMinutes != null;

  /// `true` when a date range is set.
  bool get hasDateFilter => filterStartDate != null;

  /// Creates a copy with the given fields replaced.
  ///
  /// To **clear** a nullable field, pass the special [_absent] sentinel
  /// via the named `clear*` parameters. Example:
  ///
  /// ```dart
  /// criteria.copyWith(clearBaseLocation: true);
  /// ```
  FilterCriteria copyWith({
    Object? baseLocation = _absent,
    Object? baseLocationLabel = _absent,
    Object? maxTravelTimeMinutes = _absent,
    TravelMode? travelMode,
    Object? filterStartDate = _absent,
    Object? filterEndDate = _absent,
    bool? includePerennial,
  }) {
    return FilterCriteria(
      baseLocation: baseLocation is _Absent
          ? this.baseLocation
          : baseLocation as GeoPoint?,
      baseLocationLabel: baseLocationLabel is _Absent
          ? this.baseLocationLabel
          : baseLocationLabel as String?,
      maxTravelTimeMinutes: maxTravelTimeMinutes is _Absent
          ? this.maxTravelTimeMinutes
          : maxTravelTimeMinutes as int?,
      travelMode: travelMode ?? this.travelMode,
      filterStartDate: filterStartDate is _Absent
          ? this.filterStartDate
          : filterStartDate as DateTime?,
      filterEndDate: filterEndDate is _Absent
          ? this.filterEndDate
          : filterEndDate as DateTime?,
      includePerennial: includePerennial ?? this.includePerennial,
    );
  }

  /// Resets all filter fields.
  FilterCriteria clear() => const FilterCriteria();
}
