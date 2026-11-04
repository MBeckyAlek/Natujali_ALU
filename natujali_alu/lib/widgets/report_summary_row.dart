import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/report.dart';

/// Four counters summarising a list of reports: total, submitted,
/// in progress (including under review) and resolved.
class ReportSummaryRow extends StatelessWidget {
  const ReportSummaryRow({super.key, required this.reports});

  final List<Report> reports;

  int _count(bool Function(ReportStatus status) test) =>
      reports.where((report) => test(report.status)).length;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        reports.length,
        'My reports',
        AppColors.crimsonCard,
        AppColors.primary,
      ),
      _StatTile(
        _count((s) => s == ReportStatus.submitted),
        'Submitted',
        AppColors.amber,
        AppColors.amberText,
      ),
      _StatTile(
        _count(
          (s) => s == ReportStatus.underReview || s == ReportStatus.inProgress,
        ),
        'In progress',
        AppColors.blue,
        AppColors.blueText,
      ),
      _StatTile(
        _count((s) => s == ReportStatus.resolved),
        'Resolved',
        AppColors.green,
        AppColors.greenText,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.value, this.label, this.background, this.foreground);

  final int value;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: foreground,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
