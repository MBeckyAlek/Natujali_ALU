import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/report.dart';
import 'app_card.dart';
import 'report_thumbnail.dart';
import 'status_chip.dart';

/// List item showing a report's category, reference, title, location,
/// status and age. It never shows who reported it.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontSize: 12, color: context.colors.muted);

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
                      const Spacer(),
                      Text(timeAgo(report.createdAt), style: small),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
