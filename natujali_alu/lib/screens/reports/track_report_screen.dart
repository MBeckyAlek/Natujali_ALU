import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../providers/report_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/status_chip.dart';

/// Full vertical timeline of a report, built from its status history.
class TrackReportScreen extends ConsumerWidget {
  const TrackReportScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportByIdProvider(reportId));
    if (report == null) {
      return const Scaffold(
        body: Center(child: Text('This report is no longer available.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ScreenHeader(
              eyebrow: report.reference,
              title: 'Track your report',
              showBack: true,
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(status: report.status),
                  const SizedBox(height: 8),
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    report.location,
                    style: TextStyle(color: context.colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            for (final status in ReportStatus.values)
              _TimelineStep(
                status: status,
                report: report,
                isLast: status == ReportStatus.values.last,
              ),
            const SizedBox(height: 8),
            const InfoBanner(
              title: "You're in the loop",
              message:
                  'You will be notified when this report changes. Repair timing depends '
                  'on the issue; staff confirm completion here once it is fixed.',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to report details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.report,
    required this.isLast,
  });

  final ReportStatus status;
  final Report report;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isReached = status.index <= report.status.index;
    final isCurrent =
        status == report.status && status != ReportStatus.resolved;
    // The most recent history entry for this step, if the report got here.
    final entry = report.history
        .where((update) => update.status == status)
        .lastOrNull;
    final color = isReached ? context.colors.primary : context.colors.muted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isReached
                    ? context.colors.primaryTint
                    : context.colors.surface,
                child: Icon(
                  isCurrent
                      ? Icons.radio_button_checked
                      : (isReached ? Icons.check : Icons.flag_outlined),
                  size: 16,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: status.index < report.status.index
                        ? context.colors.primary
                        : context.colors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isReached
                                ? context.colors.ink
                                : context.colors.muted,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Text(
                          'CURRENT',
                          style: TextStyle(
                            color: context.colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (entry != null) ...[
                    Text(
                      formatShortDateTime(entry.at),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(entry.note),
                  ] else
                    Text(
                      isReached ? 'Completed' : 'Not yet reached',
                      style: TextStyle(color: context.colors.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
