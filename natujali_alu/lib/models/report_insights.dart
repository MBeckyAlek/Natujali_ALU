import 'report.dart';

/// Reports opened and resolved on one calendar day.
class DayActivity {
  const DayActivity({
    required this.day,
    required this.opened,
    required this.resolved,
  });

  final DateTime day;
  final int opened;
  final int resolved;
}

/// When a resolved report was marked resolved, taken from its history.
/// Null for reports that are still open.
DateTime? resolvedAt(Report report) {
  if (report.status != ReportStatus.resolved) return null;
  return report.history
      .lastWhere(
        (update) => update.status == ReportStatus.resolved,
        orElse: () => report.latestUpdate,
      )
      .at;
}

/// Numbers for the staff dashboard, worked out from the reports already
/// loaded. Nothing extra is stored in Firestore.
class ReportInsights {
  ReportInsights(this.reports, {DateTime? now}) : now = now ?? DateTime.now();

  final List<Report> reports;
  final DateTime now;

  /// One entry per day for the last [days] days, oldest first, ending today.
  List<DayActivity> dailyActivity(int days) {
    final today = _dateOnly(now);
    return [
      for (var i = days - 1; i >= 0; i--)
        _activityOn(today.subtract(Duration(days: i))),
    ];
  }

  DayActivity _activityOn(DateTime day) {
    bool sameDay(DateTime? date) => date != null && _dateOnly(date) == day;
    return DayActivity(
      day: day,
      opened: reports.where((r) => sameDay(r.createdAt)).length,
      resolved: reports.where((r) => sameDay(resolvedAt(r))).length,
    );
  }

  /// Average time from submission to resolution. Null if nothing is resolved.
  Duration? get averageResolutionTime {
    final times = [
      for (final report in reports)
        if (resolvedAt(report) case final resolved?)
          resolved.difference(report.createdAt),
    ];
    if (times.isEmpty) return null;
    final total = times.fold(Duration.zero, (sum, time) => sum + time);
    return total ~/ times.length;
  }

  /// Reports resolved in the last 7 days.
  int get resolvedThisWeek {
    final weekAgo = now.subtract(const Duration(days: 7));
    return reports
        .where((r) => resolvedAt(r)?.isAfter(weekAgo) ?? false)
        .length;
  }

  /// How long the oldest open report has been waiting. Null if none are open.
  Duration? get longestOpenWait {
    final open = reports.where((r) => r.status.isOpen);
    if (open.isEmpty) return null;
    final oldest = open.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    );
    return now.difference(oldest.createdAt);
  }

  /// Report counts per category, largest first. Empty categories are left out.
  List<(ReportCategory, int)> get countByCategory {
    final counts = [
      for (final category in ReportCategory.values)
        (category, reports.where((r) => r.category == category).length),
    ]..removeWhere((entry) => entry.$2 == 0);
    return counts..sort((a, b) => b.$2.compareTo(a.$2));
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
