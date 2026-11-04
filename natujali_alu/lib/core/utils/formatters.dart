import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('d MMM y · h:mm a');
final _shortDateTimeFormat = DateFormat('d MMM · h:mm a');
final _dateFormat = DateFormat('d MMM y');

/// e.g. "24 Oct 2026 · 9:24 AM"
String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

/// e.g. "24 Oct · 9:24 AM"
String formatShortDateTime(DateTime date) => _shortDateTimeFormat.format(date);

/// e.g. "Just now", "5 min ago", "2 hours ago", "3 days ago".
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
  }
  if (diff.inDays < 7) {
    return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
  }
  return _dateFormat.format(date);
}
