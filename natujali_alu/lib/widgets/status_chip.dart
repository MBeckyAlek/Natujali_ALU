import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/report.dart';

/// Coloured pill showing a report's status. Always includes the text label
/// so status is never communicated by colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReportStatus status;

  static (Color background, Color foreground) colorsFor(ReportStatus status) {
    return switch (status) {
      ReportStatus.submitted => (AppColors.amber, AppColors.amberText),
      ReportStatus.underReview => (AppColors.purple, AppColors.purpleText),
      ReportStatus.inProgress => (AppColors.accentTint, AppColors.accent),
      ReportStatus.resolved => (AppColors.green, AppColors.greenText),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
