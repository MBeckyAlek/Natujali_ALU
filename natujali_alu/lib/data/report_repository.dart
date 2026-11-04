import '../models/app_user.dart';
import '../models/report.dart';

/// Create, read, update and delete operations for incident reports.
///
/// Screens depend on this interface rather than on Firestore directly, which
/// keeps data access out of the UI and makes the backend swappable.
abstract class ReportRepository {
  /// All campus reports, newest first. Emits again whenever anything changes.
  Stream<List<Report>> watchReports();

  Future<Report> createReport(ReportInput input, {required AppUser reporter});

  Future<void> updateReport(String reportId, ReportInput input);

  Future<void> deleteReport(String reportId);
}
