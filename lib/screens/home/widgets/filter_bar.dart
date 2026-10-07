import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../config/constants.dart';
import '../../../models/filter_model.dart';
import '../../../providers/filter_provider.dart';
import '../../../services/location_service.dart';
import 'travel_time_picker.dart';

/// Collapsible filter bar at the top of the home feed.
///
/// Sections:
///  1. Base location search (Places Autocomplete)
///  2. Travel-time slider
///  3. Travel-mode toggle (driving / transit / walking)
///  4. Date range via table_calendar
///  5. "Include perennial" switch
class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────
  bool _expanded = false;
  final _locationCtrl = TextEditingController();
  final _locationFocus = FocusNode();
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;

  // Local calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final _locationService = LocationService();

  // ─── Animation ──────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );

    // Sync local state from provider on init
    final criteria = ref.read(filterProvider).criteria;
    if (criteria.baseLocationLabel != null) {
      _locationCtrl.text = criteria.baseLocationLabel!;
    }
    _rangeStart = criteria.filterStartDate;
    _rangeEnd = criteria.filterEndDate;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _locationCtrl.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  // ─── Location search ────────────────────────────────────────────────

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _searching = true);
    final results = await _locationService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    }
  }

  Future<void> _onSuggestionTapped(PlaceSuggestion suggestion) async {
    _locationCtrl.text = suggestion.description;
    setState(() => _suggestions = []);
    _locationFocus.unfocus();

    final detail = await _locationService.getPlaceDetails(suggestion.placeId);
    if (detail == null) return;

    final filter = ref.read(filterProvider);
    filter.updateCriteria(filter.criteria.copyWith(
      baseLocation: GeoPoint(detail.lat, detail.lng),
      baseLocationLabel: suggestion.description,
      // Default to 60 min if no travel time was set yet
      maxTravelTimeMinutes:
          filter.criteria.maxTravelTimeMinutes ?? 60,
    ));
  }

  void _clearLocation() {
    _locationCtrl.clear();
    setState(() => _suggestions = []);
    final filter = ref.read(filterProvider);
    filter.updateCriteria(filter.criteria.copyWith(
      baseLocation: null,
      baseLocationLabel: null,
      maxTravelTimeMinutes: null,
    ));
  }

  // ─── Date range ─────────────────────────────────────────────────────

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focused) {
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      _focusedDay = focused;
    });

    final filter = ref.read(filterProvider);
    filter.updateCriteria(filter.criteria.copyWith(
      filterStartDate: start,
      filterEndDate: end,
    ));
  }

  void _clearDateRange() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
    final filter = ref.read(filterProvider);
    filter.updateCriteria(filter.criteria.copyWith(
      filterStartDate: null,
      filterEndDate: null,
    ));
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider);
    final criteria = filter.criteria;
    final dateFmt = DateFormat('MMM dd');

    return Column(
      children: [
        // ── Collapsed header ─────────────────────────────────────
        Material(
          color: theme.colorScheme.surface,
          elevation: _expanded ? 2 : 0,
          child: InkWell(
            onTap: _toggleExpand,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: criteria.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: criteria.isActive
                        ? _ActiveFilterSummary(
                            criteria: criteria,
                            dateFmt: dateFmt,
                            theme: theme,
                          )
                        : Text(
                            'Filters',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                  if (criteria.isActive)
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: theme.colorScheme.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _clearLocation();
                        _clearDateRange();
                        ref.read(filterProvider).clearAll();
                      },
                      tooltip: 'Clear filters',
                    ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnim),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 22,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Expanded body ────────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1,
          child: Container(
            color: theme.colorScheme.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Base location search ────────────────────
                Text('Base Location',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationCtrl,
                  focusNode: _locationFocus,
                  decoration: InputDecoration(
                    hintText: 'Search a location...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _locationCtrl.text.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.close_rounded, size: 18),
                            onPressed: _clearLocation,
                          )
                        : null,
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),

                // Suggestions dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.place_outlined,
                              size: 18,
                              color: theme.colorScheme.primary),
                          title: Text(s.description,
                              style: theme.textTheme.bodySmall),
                          onTap: () => _onSuggestionTapped(s),
                        );
                      },
                    ),
                  ),

                if (_searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),

                // ── 2. Travel time slider ──────────────────────
                if (criteria.baseLocation != null) ...[
                  const SizedBox(height: 16),
                  TravelTimePicker(
                    value: criteria.maxTravelTimeMinutes ?? 60,
                    onChanged: (v) {
                      filter.updateCriteria(
                          criteria.copyWith(maxTravelTimeMinutes: v));
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── 3. Travel mode toggle ──────────────────────
                  _TravelModeSelector(
                    selected: criteria.travelMode,
                    onChanged: (mode) {
                      filter.updateCriteria(
                          criteria.copyWith(travelMode: mode));
                    },
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── 4. Date range calendar ─────────────────────
                Row(
                  children: [
                    Text('Event Date Filter',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    const Spacer(),
                    if (_rangeStart != null)
                      TextButton.icon(
                        onPressed: _clearDateRange,
                        icon: Icon(Icons.close_rounded,
                            size: 14, color: theme.colorScheme.error),
                        label: Text('Clear',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.error,
                            )),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Calendar
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.04),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDay:
                        DateTime.now().add(const Duration(days: 365 * 2)),
                    focusedDay: _focusedDay,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    onRangeSelected: _onRangeSelected,
                    onPageChanged: (day) =>
                        setState(() => _focusedDay = day),
                    calendarStyle: CalendarStyle(
                      rangeHighlightColor: theme.colorScheme.primary
                          .withValues(alpha: 0.15),
                      rangeStartDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                      cellMargin: const EdgeInsets.all(2),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      leftChevronIcon: Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: theme.colorScheme.primary),
                      rightChevronIcon: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: theme.colorScheme.primary),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                      weekendStyle: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                  ),
                ),

                const SizedBox(height: 12),

                // ── 5. Include perennial switch ────────────────
                Row(
                  children: [
                    Icon(Icons.all_inclusive_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Include perennial events',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: criteria.includePerennial,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) {
                        filter.updateCriteria(
                            criteria.copyWith(includePerennial: v));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Active filter summary (collapsed view) ────────────────────────────

class _ActiveFilterSummary extends StatelessWidget {
  final FilterCriteria criteria;
  final DateFormat dateFmt;
  final ThemeData theme;

  const _ActiveFilterSummary({
    required this.criteria,
    required this.dateFmt,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (criteria.hasTravelFilter) {
      final mode = switch (criteria.travelMode) {
        TravelMode.driving => '🚗',
        TravelMode.transit => '🚌',
        TravelMode.walking => '🚶',
      };
      final time = _formatMinutes(criteria.maxTravelTimeMinutes!);
      parts.add('$mode ≤ $time');
    }

    if (criteria.hasDateFilter) {
      final start = dateFmt.format(criteria.filterStartDate!);
      if (criteria.filterEndDate != null) {
        final end = dateFmt.format(criteria.filterEndDate!);
        parts.add('📅 $start – $end');
      } else {
        parts.add('📅 $start');
      }
    }

    return Text(
      parts.join('  •  '),
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ─── Travel mode selector ──────────────────────────────────────────────

class _TravelModeSelector extends StatelessWidget {
  final TravelMode selected;
  final ValueChanged<TravelMode> onChanged;

  const _TravelModeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.directions_rounded,
            size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          'Mode',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<TravelMode>(
            segments: const [
              ButtonSegment(
                value: TravelMode.driving,
                icon: Icon(Icons.directions_car_rounded, size: 18),
                label: Text('Car'),
              ),
              ButtonSegment(
                value: TravelMode.transit,
                icon: Icon(Icons.directions_transit_rounded, size: 18),
                label: Text('Transit'),
              ),
              ButtonSegment(
                value: TravelMode.walking,
                icon: Icon(Icons.directions_walk_rounded, size: 18),
                label: Text('Walk'),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
