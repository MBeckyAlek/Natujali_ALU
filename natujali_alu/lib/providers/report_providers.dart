import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_report_repository.dart';
import '../data/report_repository.dart';
import '../models/achievements.dart';
import '../models/report.dart';
import '../models/report_filter.dart';
import '../models/rewards.dart';
import 'auth_providers.dart';

/// Use FakeReportRepository() here instead to run the app without Firebase.
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => FirestoreReportRepository(),
);

/// Every campus report, kept live. All other report providers derive from
/// this one, so a change made anywhere shows up on every screen.
final reportsProvider = StreamProvider<List<Report>>((ref) {
  // The security rules only let verified users read reports, so wait until
  // someone is signed in and verified. Re-runs when that user changes.
  final user = ref.watch(
    currentUserProvider.select(
      (u) => (uid: u?.uid, verified: u?.emailVerified),
    ),
  );
  if (user.uid == null || user.verified != true) return Stream.value(const []);
  return ref.watch(reportRepositoryProvider).watchReports();
});

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

/// The signed-in student's coins from resolved reports.
final coinSummaryProvider = Provider<CoinSummary>(
  (ref) => CoinSummary(ref.watch(myReportsProvider).value ?? const []),
);

/// The signed-in student's badges and progress towards them.
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return achievementsFor(
    uid: uid,
    allReports: ref.watch(reportsProvider).value ?? const [],
  );
});
