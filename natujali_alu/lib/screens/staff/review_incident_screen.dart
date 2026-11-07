import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/report_providers.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/priority_chip.dart';
import '../../widgets/report_photo.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/status_chip.dart';
import '../reports/status_timeline_bar.dart';
import '../reports/track_report_screen.dart';
import 'status_update_form.dart';

/// Staff view of one report: everything about it, who reported it, and the
/// form to move it forward.
class ReviewIncidentScreen extends ConsumerWidget {
  const ReviewIncidentScreen({super.key, required this.reportId});

  final String reportId;

  static Future<void> open(BuildContext context, String reportId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewIncidentScreen(reportId: reportId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportByIdProvider(reportId));
    if (report == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                ScreenHeader(title: 'Review incident', showBack: true),
                EmptyState(
                  icon: Icons.search_off,
                  title: 'Report not available',
                  message: 'The student may have deleted it before review.',
                ),
              ],
            ),
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ScreenHeader(
              eyebrow: report.reference,
              title: 'Review incident',
              showBack: true,
            ),
            Row(
              children: [
                Icon(report.category.icon, size: 18, color: c.primary),
                const SizedBox(width: 6),
                Text(
                  report.category.label,
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                PriorityChip(priority: report.priority),
                const SizedBox(width: 6),
                StatusChip(status: report.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.title, style: textTheme.headlineSmall),
            Text(report.location, style: TextStyle(color: c.muted)),
            const SizedBox(height: 4),
            Text(
              [
                'Reported ${timeAgo(report.createdAt)}',
                ?dueLabel(report, DateTime.now()),
              ].join(' · '),
              style: textTheme.bodySmall?.copyWith(
                color: report.isOverdue(DateTime.now()) ? c.accent : null,
              ),
            ),
            if (report.supporters.isNotEmpty) ...[
              const SizedBox(height: 12),
              InfoBanner(
                icon: Icons.people_outline,
                title:
                    '${report.supporters.length} more '
                    '${report.supporters.length == 1 ? 'student is' : 'students are'} '
                    'affected',
                message:
                    'They tapped "Me too" instead of filing a duplicate. '
                    'Consider raising the priority.',
              ),
            ],
            const SizedBox(height: 16),
            AppCard(child: StatusTimelineBar(current: report.status)),
            const SizedBox(height: 20),
            Text('What was reported', style: textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(report.description, style: textTheme.bodyLarge),
            if (report.photoPath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ReportPhoto(
                  path: report.photoPath!,
                  height: 200,
                  width: double.infinity,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _ReporterCard(reporterId: report.reporterId),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  DetailRow(
                    label: 'Submitted',
                    value: formatDateTime(report.createdAt),
                  ),
                  DetailRow(
                    label: 'Assigned to',
                    value: report.assignedTeam ?? 'Not assigned yet',
                  ),
                  DetailRow(
                    label: 'Priority',
                    value:
                        '${report.priority.label}'
                        '${report.staffPriority == null ? ' (default)' : ''}'
                        ' · resolve by ${formatDateTime(report.dueAt)}',
                  ),
                  DetailRow(
                    label: 'Last updated',
                    value: formatDateTime(report.updatedAt),
                  ),
                  DetailRow(
                    label: 'Updates',
                    value: '${report.history.length} in history',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrackReportScreen(reportId: report.id),
                  ),
                ),
                icon: const Icon(Icons.timeline),
                label: const Text('View full history'),
              ),
            ),
            const SizedBox(height: 12),
            Text('Update status', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'The student sees your note in their notifications.',
              style: textTheme.bodySmall,
            ),
            // Keyed by report so the form resets if the report is swapped.
            StatusUpdateForm(key: ValueKey(report.id), report: report),
          ],
        ),
      ),
    );
  }
}

/// Who filed the report. Visible to staff only, so they can follow up.
class _ReporterCard extends ConsumerWidget {
  const _ReporterCard({required this.reporterId});

  final String reporterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reporter = ref.watch(reporterProvider(reporterId));
    final c = context.colors;

    return AppCard(
      color: c.primaryTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Text(
                'Reporter · staff only',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          reporter.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) =>
                const Text("Couldn't load the reporter's details."),
            data: (user) => user == null
                ? const Text('Reporter details are not available.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(user.email),
                      if (user.studentId.isNotEmpty) Text(user.studentId),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'Never include names or contact details in status notes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
