import 'report.dart';

/// Search text plus optional category, status and building filters.
/// An empty set or null building means "don't filter on this".
class ReportFilter {
  const ReportFilter({
    this.query = '',
    this.categories = const {},
    this.statuses = const {},
    this.building,
  });

  final String query;
  final Set<ReportCategory> categories;
  final Set<ReportStatus> statuses;
  final String? building;

  bool get hasFilters =>
      categories.isNotEmpty || statuses.isNotEmpty || building != null;

  ReportFilter copyWith({String? query, Set<ReportStatus>? statuses}) {
    return ReportFilter(
      query: query ?? this.query,
      categories: categories,
      statuses: statuses ?? this.statuses,
      building: building,
    );
  }

  bool matches(Report report) {
    if (categories.isNotEmpty && !categories.contains(report.category)) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(report.status)) return false;
    if (building != null && report.building != building) return false;

    final text = query.trim().toLowerCase();
    if (text.isEmpty) return true;
    return report.title.toLowerCase().contains(text) ||
        report.reference.toLowerCase().contains(text) ||
        report.location.toLowerCase().contains(text);
  }

  List<Report> apply(List<Report> reports) => reports.where(matches).toList();
}

/// Open reports in the same category and building, used to warn a student
/// before they submit a duplicate.
List<Report> findSimilarOpenReports(
  List<Report> reports, {
  required ReportCategory category,
  required String building,
  String? excludeId,
}) {
  return reports
      .where(
        (report) =>
            report.id != excludeId &&
            report.status.isOpen &&
            report.category == category &&
            report.building == building,
      )
      .toList();
}
