import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../models/rewards.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_photo.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/status_chip.dart';
import '../report_form/report_form_screen.dart';
import '../rewards/rewards_screen.dart';
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
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(e, action: 'delete the report'))),
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
            if (!isOwn && user != null && report.status.isOpen) ...[
              const SizedBox(height: 12),
              _MeTooButton(report: report, uid: user.uid),
            ] else if (isOwn && report.supporters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${report.supporters.length} more '
                '${report.supporters.length == 1 ? 'student says' : 'students say'} '
                'this affects them too.',
                style: TextStyle(color: context.colors.primary, fontSize: 13),
              ),
            ],
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
            if (isOwn) ...[
              const SizedBox(height: 12),
              AppCard(
                color: context.colors.amber,
                onTap: () => RewardsScreen.open(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: context.colors.amberText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        report.status == ReportStatus.resolved
                            ? 'This report earned you ${coinsFor(report)} coins.'
                            : 'Earn up to $maxCoinsPerReport coins when this '
                                  'report is resolved.',
                        style: TextStyle(
                          color: context.colors.amberText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

/// "Me too" on someone else's open report: shows that the issue affects
/// more students, which helps staff prioritise, instead of a duplicate.
class _MeTooButton extends ConsumerStatefulWidget {
  const _MeTooButton({required this.report, required this.uid});

  final Report report;
  final String uid;

  @override
  ConsumerState<_MeTooButton> createState() => _MeTooButtonState();
}

class _MeTooButtonState extends ConsumerState<_MeTooButton> {
  bool _isSaving = false;

  Future<void> _toggle(bool support) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(reportRepositoryProvider)
          .setSupport(widget.report.id, uid: widget.uid, support: support);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            support
                ? 'Added. Staff can see this affects more students.'
                : 'Removed your "Me too".',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(e, action: 'save your "Me too"'))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = widget.report.isSupportedBy(widget.uid);
    final others = widget.report.supporters.length;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              others == 0
                  ? 'Affected by this too? Let staff know instead of '
                        'filing a duplicate.'
                  : '$others ${others == 1 ? 'student has' : 'students have'} '
                        'said this affects them too.',
              style: TextStyle(color: context.colors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          supported
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _isSaving ? null : () => _toggle(false),
                  icon: const Icon(Icons.check),
                  label: const Text('Me too'),
                )
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: _isSaving ? null : () => _toggle(true),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Me too'),
                ),
        ],
      ),
    );
  }
}
