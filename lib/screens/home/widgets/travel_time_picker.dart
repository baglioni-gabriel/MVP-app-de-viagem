import 'package:flutter/material.dart';

/// Slider widget for selecting maximum travel time.
///
/// Displays predefined time labels (15 min → 8 hrs) with a smooth
/// slider. The selected value is emitted via [onChanged].
class TravelTimePicker extends StatelessWidget {
  /// Current value in minutes.
  final int value;

  /// Callback when the user drags the slider.
  final ValueChanged<int> onChanged;

  const TravelTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  // Predefined stops in minutes
  static const List<int> _stops = [
    15, 30, 45, 60, 90, 120, 180, 240, 360, 480,
  ];

  static String _label(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find closest stop index
    int stopIndex = 0;
    for (var i = 0; i < _stops.length; i++) {
      if (_stops[i] <= value) stopIndex = i;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with current value
        Row(
          children: [
            Icon(Icons.timer_outlined,
                size: 18,
                color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Max travel time',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _label(value),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            min: 0,
            max: (_stops.length - 1).toDouble(),
            divisions: _stops.length - 1,
            value: stopIndex.toDouble(),
            onChanged: (v) => onChanged(_stops[v.round()]),
          ),
        ),

        // Min/max labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_label(_stops.first),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  )),
              Text(_label(_stops.last),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
