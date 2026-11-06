import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_photo.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/status_chip.dart';
import '../report_form/report_form_screen.dart';
import 'status_timeline_bar.dart';
import 'track_report_screen.dart';

class ReportDetailsScreen extends ConsumerWidget {
  const ReportDetailsScreen({super.key, required this.reportId});

  final String reportId;

  static Future<void> open(BuildContext context, String reportId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(reportId: reportId),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Report report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this report?'),
        content: Text(
          '${report.reference} will be removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(reportRepositoryProvider).deleteReport(report.id);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${report.reference} was deleted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't delete the report. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportByIdProvider(reportId));
    final user = ref.watch(currentUserProvider);

    if (report == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                ScreenHeader(title: 'Report details', showBack: true),
                EmptyState(
                  icon: Icons.search_off,
                  title: 'Report not available',
                  message:
                      'It may have been deleted by the person who reported it.',
                ),
              ],
            ),
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final isOwn = report.reporterId == user?.uid;
    final latest = report.latestUpdate;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ScreenHeader(
              eyebrow: report.reference,
              title: 'Report details',
              showBack: true,
            ),
            Row(
              children: [
                Icon(
                  report.category.icon,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  report.category.label,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                StatusChip(status: report.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.title, style: textTheme.headlineSmall),
            Text(
              report.location,
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS TIMELINE',
                    style: textTheme.labelSmall?.copyWith(
                      color: context.colors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusTimelineBar(current: report.status),
                ],
              ),
            ),
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
            AppCard(
              child: Column(
                children: [
                  DetailRow(
                    label: 'Reported by',
                    // Other students never see who filed a report.
                    value: isOwn
                        ? 'You · ${user!.fullName}'
                        : 'A student (kept private)',
                  ),
                  DetailRow(
                    label: 'Submitted',
                    value: formatDateTime(report.createdAt),
                  ),
                  DetailRow(
                    label: 'Assigned to',
                    value: report.assignedTeam ?? 'Not assigned yet',
                  ),
                  DetailRow(
                    label: 'Last updated',
                    value: formatDateTime(report.updatedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Latest update', style: textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('"${latest.note}"', style: textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              '${latest.updatedBy} · ${formatShortDateTime(latest.at)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackReportScreen(reportId: report.id),
                ),
              ),
              icon: const Icon(Icons.timeline),
              label: const Text('View status timeline'),
            ),
            if (report.canBeEditedBy(user?.uid)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ReportFormScreen.open(context, existing: report),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref, report),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You can edit or delete this report until staff start reviewing it.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
