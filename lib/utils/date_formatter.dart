import 'package:intl/intl.dart';

/// Date / time formatting helpers.
class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _dateTimeFormat = DateFormat('MMM dd, yyyy – HH:mm');
  static final _timeFormat = DateFormat('HH:mm');

  /// e.g. "Apr 26, 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// e.g. "Apr 26, 2026 – 14:30"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// e.g. "14:30"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Returns a human-readable relative string like "2 hours ago".
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }
}
