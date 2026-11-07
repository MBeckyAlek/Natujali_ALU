import 'report.dart';
import 'report_insights.dart';

/// Coins a student earns when staff resolve one of their reports.
const coinsPerResolvedReport = 10;

/// Extra coins when the report came with a photo, which helps staff
/// find and fix the issue faster.
const photoBonusCoins = 5;

/// The most a single report can earn.
const maxCoinsPerReport = coinsPerResolvedReport + photoBonusCoins;

/// Coins earned by [report]: nothing until staff mark it resolved.
int coinsFor(Report report) {
  if (report.status != ReportStatus.resolved) return 0;
  return coinsPerResolvedReport +
      (report.photoPath != null ? photoBonusCoins : 0);
}

/// One resolved report and the coins it earned.
class CoinEntry {
  const CoinEntry({
    required this.report,
    required this.coins,
    required this.earnedAt,
  });

  final Report report;
  final int coins;
  final DateTime earnedAt;
}

/// A student's coins, worked out from their own reports. Nothing is stored,
/// so the balance can't be edited: only staff can resolve a report.
class CoinSummary {
  CoinSummary(List<Report> myReports)
    : entries = [
        for (final report in myReports)
          if (coinsFor(report) > 0)
            CoinEntry(
              report: report,
              coins: coinsFor(report),
              earnedAt: resolvedAt(report)!,
            ),
      ]..sort((a, b) => b.earnedAt.compareTo(a.earnedAt)),
      pendingReports = myReports.where((r) => r.status.isOpen).length;

  /// Newest first.
  final List<CoinEntry> entries;

  /// Open reports that will earn coins once resolved.
  final int pendingReports;

  int get balance => entries.fold(0, (sum, entry) => sum + entry.coins);
}
