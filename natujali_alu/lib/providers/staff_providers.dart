import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/report.dart';
import 'auth_providers.dart';

/// The person who filed a report. Only staff can load this; students never
/// see who reported what.
final reporterProvider = FutureProvider.family<AppUser?, String>(
  (ref, uid) => ref.watch(authRepositoryProvider).fetchUser(uid),
);

/// Tabs on the staff queue.
enum QueueTab {
  open('Open'),
  submitted('New'),
  underReview('Under review'),
  inProgress('In progress'),
  resolved('Resolved'),
  all('All');

  const QueueTab(this.label);

  final String label;

  bool matches(Report report) {
    return switch (this) {
      QueueTab.open => report.status.isOpen,
      QueueTab.submitted => report.status == ReportStatus.submitted,
      QueueTab.underReview => report.status == ReportStatus.underReview,
      QueueTab.inProgress => report.status == ReportStatus.inProgress,
      QueueTab.resolved => report.status == ReportStatus.resolved,
      QueueTab.all => true,
    };
  }

  bool get newestFirst => this == QueueTab.resolved || this == QueueTab.all;

  /// Open work is shown by due time, so overdue and urgent reports come
  /// first; resolved and "All" show the most recent first.
  List<Report> sort(List<Report> reports) {
    final sorted = [...reports];
    if (newestFirst) {
      sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else {
      sorted.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    }
    return sorted;
  }
}

/// Tab plus the extra filters on the staff Reports screen. Null means
/// "don't filter on this". Kept in a provider so the dashboard can open
/// the Reports tab already filtered.
class StaffQueueFilter {
  const StaffQueueFilter({
    this.tab = QueueTab.open,
    this.category,
    this.priority,
    this.overdueOnly = false,
    this.team,
    this.building,
    this.from,
    this.to,
  });

  final QueueTab tab;
  final ReportCategory? category;
  final ReportPriority? priority;

  /// Only reports past their priority's time target.
  final bool overdueOnly;
  final String? team;
  final String? building;

  /// Submission date range, both days included.
  final DateTime? from;
  final DateTime? to;

  bool get hasExtras =>
      category != null ||
      priority != null ||
      overdueOnly ||
      team != null ||
      building != null ||
      from != null ||
      to != null;

  /// The month picked with the Month filter, if the dates cover exactly
  /// one whole month.
  DateTime? get month {
    if (from == null || to == null) return null;
    final start = DateTime(from!.year, from!.month);
    final end = DateTime(start.year, start.month + 1, 0);
    return from == start && to == end ? start : null;
  }

  bool matches(Report report) {
    if (!tab.matches(report)) return false;
    if (category != null && report.category != category) return false;
    if (priority != null && report.priority != priority) return false;
    if (overdueOnly && !report.isOverdue(DateTime.now())) return false;
    if (team != null && report.assignedTeam != team) return false;
    if (building != null && report.building != building) return false;
    if (from != null && report.createdAt.isBefore(from!)) return false;
    final end = to?.add(const Duration(days: 1));
    if (end != null && !report.createdAt.isBefore(end)) return false;
    return true;
  }
}

class StaffQueueFilterNotifier extends Notifier<StaffQueueFilter> {
  @override
  StaffQueueFilter build() => const StaffQueueFilter();

  void selectTab(QueueTab tab) => _set(tab: tab);

  /// Starts fresh on [tab], e.g. when a dashboard counter is tapped.
  void show(
    QueueTab tab, {
    ReportCategory? category,
    bool overdueOnly = false,
  }) => state = StaffQueueFilter(
    tab: tab,
    category: category,
    overdueOnly: overdueOnly,
  );

  void setCategory(ReportCategory? category) => _set(category: () => category);

  void setTeam(String? team) => _set(team: () => team);

  void setPriority(ReportPriority? priority) => _set(priority: () => priority);

  void setOverdueOnly(bool value) => _set(overdueOnly: value);

  void setBuilding(String? building) => _set(building: () => building);

  /// Filters to reports submitted in [month], or clears the dates if null.
  void setMonth(DateTime? month) => month == null
      ? setDates(null, null)
      : setDates(month, DateTime(month.year, month.month + 1, 0));

  void setDates(DateTime? from, DateTime? to) =>
      _set(from: () => from, to: () => to);

  /// Clears everything except the tab.
  void clearExtras() => state = StaffQueueFilter(tab: state.tab);

  /// Nullable fields are passed as functions so null can mean "clear it"
  /// while a missing argument means "keep it".
  void _set({
    QueueTab? tab,
    ReportCategory? Function()? category,
    ReportPriority? Function()? priority,
    bool? overdueOnly,
    String? Function()? team,
    String? Function()? building,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) {
    state = StaffQueueFilter(
      tab: tab ?? state.tab,
      category: category != null ? category() : state.category,
      priority: priority != null ? priority() : state.priority,
      overdueOnly: overdueOnly ?? state.overdueOnly,
      team: team != null ? team() : state.team,
      building: building != null ? building() : state.building,
      from: from != null ? from() : state.from,
      to: to != null ? to() : state.to,
    );
  }
}

final staffQueueFilterProvider =
    NotifierProvider<StaffQueueFilterNotifier, StaffQueueFilter>(
      StaffQueueFilterNotifier.new,
    );

/// Open reports past their priority's time target, most overdue first.
List<Report> overdueReports(List<Report> reports) {
  final now = DateTime.now();
  return reports.where((r) => r.isOverdue(now)).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
}

/// Open reports ordered by how many students said "Me too".
List<Report> mostBackedReports(List<Report> reports) {
  return reports
      .where((r) => r.status.isOpen && r.supporters.isNotEmpty)
      .toList()
    ..sort((a, b) => b.supporters.length.compareTo(a.supporters.length));
}
