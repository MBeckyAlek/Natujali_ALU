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

  /// Staff only: moves a report to [status] and adds [note] to its history,
  /// which also shows up in the student's notifications.
  Future<void> updateStatus(
    String reportId, {
    required ReportStatus status,
    required String note,
    String? assignedTeam,
    ReportPriority? priority,
  });

  /// Adds or removes the student's "Me too" on someone else's open report.
  Future<void> setSupport(
    String reportId, {
    required String uid,
    required bool support,
  });
}
