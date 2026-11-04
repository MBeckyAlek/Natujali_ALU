import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_report_repository.dart';
import '../data/report_repository.dart';
import '../models/report.dart';
import '../models/report_filter.dart';
import 'auth_providers.dart';

/// Swap FakeReportRepository for the Firestore version here once it's ready.
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => FakeReportRepository(),
);

/// Every campus report, kept live. All other report providers derive from
/// this one, so a change made anywhere shows up on every screen.
final reportsProvider = StreamProvider<List<Report>>(
  (ref) => ref.watch(reportRepositoryProvider).watchReports(),
);

/// Reports submitted by the signed-in student.
final myReportsProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  return ref
      .watch(reportsProvider)
      .whenData(
        (reports) => reports.where((r) => r.reporterId == uid).toList(),
      );
});

/// A single report, or null if it doesn't exist (e.g. it was deleted).
final reportByIdProvider = Provider.family<Report?, String>((ref, id) {
  final reports = ref.watch(reportsProvider).value ?? const [];
  return reports.where((report) => report.id == id).firstOrNull;
});

/// Search and filter choices for the campus reports list. Shared between
/// the list screen and the filter screen.
class CampusFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => const ReportFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setStatuses(Set<ReportStatus> statuses) =>
      state = state.copyWith(statuses: statuses);

  void replace(ReportFilter filter) => state = filter;
}

final campusFilterProvider =
    NotifierProvider<CampusFilterNotifier, ReportFilter>(
      CampusFilterNotifier.new,
    );

final filteredCampusReportsProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final filter = ref.watch(campusFilterProvider);
  return ref.watch(reportsProvider).whenData(filter.apply);
});
