import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/constants.dart';

/// All availability data returned by [AvailabilityPickerWidget].
class AvailabilityData {
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final bool isPerennial;
  final String operatingHours;
  final List<String> unavailableDays;

  const AvailabilityData({
    required this.startDateTime,
    this.endDateTime,
    required this.isPerennial,
    required this.operatingHours,
    required this.unavailableDays,
  });
}

/// Availability picker widget — a self-contained section that lets the
/// user configure:
///
/// 1. **Start date + time** (required)
/// 2. **End date + time** (optional — toggle "Perennial" to disable)
/// 3. **Operating hours** (free-text string, e.g. "09:00 – 18:00")
/// 4. **Unavailable days** (day-of-week checkboxes)
///
/// The parent can read the current state at any time via [onChanged],
/// which fires on every user interaction.
class AvailabilityPickerWidget extends StatefulWidget {
  final ValueChanged<AvailabilityData> onChanged;

  /// Optional initial data for edit mode.
  final AvailabilityData? initial;

  const AvailabilityPickerWidget({
    super.key,
    required this.onChanged,
    this.initial,
  });

  @override
  State<AvailabilityPickerWidget> createState() =>
      _AvailabilityPickerWidgetState();
}

class _AvailabilityPickerWidgetState extends State<AvailabilityPickerWidget> {
  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  late bool _isPerennial;
  final _hoursCtrl = TextEditingController();
  late Set<Weekday> _unavailableDays;

  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _startDate = i?.startDateTime ?? DateTime.now();
    _startTime = i != null
        ? TimeOfDay.fromDateTime(i.startDateTime)
        : TimeOfDay.now();
    _isPerennial = i?.isPerennial ?? true;
    if (!_isPerennial && i?.endDateTime != null) {
      _endDate = i!.endDateTime;
      _endTime = TimeOfDay.fromDateTime(i.endDateTime!);
    }
    _hoursCtrl.text = i?.operatingHours ?? '';
    _unavailableDays = (i?.unavailableDays ?? [])
        .map((d) => Weekday.values.firstWhere((w) => w.label == d,
            orElse: () => Weekday.monday))
        .toSet();
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime? end;
    if (!_isPerennial && _endDate != null) {
      final et = _endTime ?? const TimeOfDay(hour: 23, minute: 59);
      end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        et.hour,
        et.minute,
      );
    }

    widget.onChanged(AvailabilityData(
      startDateTime: start,
      endDateTime: end,
      isPerennial: _isPerennial,
      operatingHours: _hoursCtrl.text.trim(),
      unavailableDays: _unavailableDays.map((d) => d.label).toList(),
    ));
  }

  // ─── Pickers ────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) {
      setState(() => _startDate = d);
      _emit();
    }
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: _startTime);
    if (t != null) {
      setState(() => _startTime = t);
      _emit();
    }
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (d != null) {
      setState(() => _endDate = d);
      _emit();
    }
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(
        context: context,
        initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0));
    if (t != null) {
      setState(() => _endTime = t);
      _emit();
    }
  }

  String _fmtDate(DateTime d) => _dateFormat.format(d);
  String _fmtTime(TimeOfDay t) =>
      _timeFormat.format(DateTime(0, 1, 1, t.hour, t.minute));

  // ─── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Availability',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // ── Start date / time ────────────────────────────────
        Text('Start', style: subStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _DateTimeTile(
                icon: Icons.calendar_today_rounded,
                label: _fmtDate(_startDate),
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateTimeTile(
                icon: Icons.access_time_rounded,
                label: _fmtTime(_startTime),
                onTap: _pickStartTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Perennial toggle ─────────────────────────────────
        SwitchListTile.adaptive(
          value: _isPerennial,
          onChanged: (v) {
            setState(() {
              _isPerennial = v;
              if (v) {
                _endDate = null;
                _endTime = null;
              }
            });
            _emit();
          },
          title: const Text('Perennial (no end date)'),
          subtitle: Text(
            'The event/service runs indefinitely.',
            style: subStyle,
          ),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),

        // ── End date / time (only when NOT perennial) ────────
        if (!_isPerennial) ...[
          const SizedBox(height: 8),
          Text('End', style: subStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DateTimeTile(
                  icon: Icons.calendar_today_rounded,
                  label:
                      _endDate != null ? _fmtDate(_endDate!) : 'Pick date',
                  onTap: _pickEndDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeTile(
                  icon: Icons.access_time_rounded,
                  label: _endTime != null
                      ? _fmtTime(_endTime!)
                      : 'Pick time',
                  onTap: _pickEndTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── Operating hours ──────────────────────────────────
        const SizedBox(height: 4),
        TextFormField(
          controller: _hoursCtrl,
          decoration: const InputDecoration(
            labelText: 'Operating Hours',
            hintText: 'e.g. 09:00 – 18:00',
            prefixIcon: Icon(Icons.schedule_rounded),
          ),
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 16),

        // ── Unavailable days ─────────────────────────────────
        Text('Unavailable Days', style: subStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: Weekday.values.map((day) {
            final selected = _unavailableDays.contains(day);
            return FilterChip(
              label: Text(day.label.substring(0, 3)),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _unavailableDays.add(day);
                  } else {
                    _unavailableDays.remove(day);
                  }
                });
                _emit();
              },
              selectedColor:
                  theme.colorScheme.error.withValues(alpha: 0.18),
              checkmarkColor: theme.colorScheme.error,
              labelStyle: TextStyle(
                color: selected
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Small tappable tile with an icon and label — used for date/time selectors.
class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
