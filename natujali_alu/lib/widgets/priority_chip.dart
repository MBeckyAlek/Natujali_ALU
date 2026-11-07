import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/report.dart';

/// Small pill showing a report's priority. Staff screens only.
class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final ReportPriority priority;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, foreground) = switch (priority) {
      ReportPriority.urgent => (c.accentTint, c.accent),
      ReportPriority.high => (c.amber, c.amberText),
      ReportPriority.normal => (c.primaryTint, c.primary),
      ReportPriority.low => (c.background, c.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "Overdue by 5 h" or "Due in 2 d", or null once a report is resolved.
String? dueLabel(Report report, DateTime now) {
  if (!report.status.isOpen) return null;
  final left = report.dueAt.difference(now);
  return left.isNegative
      ? 'Overdue by ${formatDuration(-left)}'
      : 'Due in ${formatDuration(left)}';
}
