import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/status_chip.dart';
import '../reports/report_details_screen.dart';

/// Confirmation shown right after a report is submitted.
class ReportReceivedScreen extends ConsumerWidget {
  const ReportReceivedScreen({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(title: 'Report received', showBack: true),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: context.colors.primaryTint,
                child: Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: context.colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thanks for speaking up, ${user?.firstName ?? 'there'}.',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your report is safely submitted. The campus team will review it next.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR REPORT REFERENCE', style: textTheme.labelSmall),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.reference,
                          style: TextStyle(
                            color: context.colors.primary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy reference',
                        icon: Icon(Icons.copy, color: context.colors.primary),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: report.reference),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reference copied.')),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    '${report.title} — ${report.building}',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: 'Submitted',
                    value: formatDateTime(report.createdAt),
                  ),
                  DetailRow(label: 'Reported by', value: user?.fullName ?? ''),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Status',
                          style: TextStyle(color: context.colors.muted),
                        ),
                      ),
                      StatusChip(status: report.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('What happens next?', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const _NextStep(
              Icons.inbox_outlined,
              'The campus team reviews your report.',
            ),
            const _NextStep(
              Icons.notifications_none,
              'You are notified when the status changes.',
            ),
            const _NextStep(
              Icons.timeline,
              'Track progress anytime in My reports.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ReportDetailsScreen(reportId: report.id),
                ),
              ),
              icon: const Icon(Icons.timeline),
              label: const Text('Track this report'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: context.colors.muted)),
          ),
        ],
      ),
    );
  }
}
