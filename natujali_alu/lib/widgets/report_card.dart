import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/report.dart';
import 'app_card.dart';
import 'priority_chip.dart';
import 'report_thumbnail.dart';
import 'status_chip.dart';

/// List item showing a report's category, reference, title, location,
/// status, age and "Me too" count. It never shows who reported it.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.forStaff = false,
  });

  final Report report;
  final VoidCallback onTap;

  /// Adds the priority and time left to the staff queue's cards.
  final bool forStaff;

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontSize: 12, color: context.colors.muted);
    final now = DateTime.now();
    final due = forStaff ? dueLabel(report, now) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            ReportThumbnail(report: report),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        report.category.icon,
                        size: 14,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${report.category.label} · ${report.reference}',
                          style: small,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: context.colors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: context.colors.muted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          report.location,
                          style: small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusChip(status: report.status),
                      if (forStaff) ...[
                        const SizedBox(width: 6),
                        PriorityChip(priority: report.priority),
                      ],
                      const Spacer(),
                      if (report.supporters.isNotEmpty) ...[
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: context.colors.muted,
                        ),
                        const SizedBox(width: 2),
                        Text('${report.supporters.length}', style: small),
                        const SizedBox(width: 8),
                      ],
                      Text(timeAgo(report.createdAt), style: small),
                    ],
                  ),
                  if (due != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      due,
                      style: small.copyWith(
                        color: report.isOverdue(now)
                            ? context.colors.accent
                            : context.colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
