import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/report.dart';
import '../../models/report_filter.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_card.dart';
import '../../widgets/report_summary_row.dart';
import '../../widgets/screen_header.dart';
import '../report_form/report_form_screen.dart';
import 'report_details_screen.dart';

/// The signed-in student's own reports with a status filter and search.
class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyReportsScreen()));
  }

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  // Filter choices only matter on this screen, so local state is enough.
  ReportStatus? _status;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myReports = ref.watch(myReportsProvider);
    final filter = ReportFilter(
      query: _query,
      statuses: _status == null ? const {} : {_status!},
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ScreenHeader(
              eyebrow: 'Your campus contributions',
              title: 'My reports',
              showBack: true,
              trailing: IconButton(
                tooltip: 'Report an issue',
                color: context.colors.primary,
                icon: const Icon(Icons.add),
                onPressed: () => ReportFormScreen.open(context),
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ReportSummaryRow(reports: myReports.value ?? const []),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Every report is a step toward a better campus.',
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _pill('All', null),
                  for (final status in ReportStatus.values)
                    _pill(status.label, status),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search your reports',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            myReports.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const EmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load your reports",
                message: 'Check your connection and try again.',
              ),
              data: (reports) {
                final visible = filter.apply(reports);
                if (reports.isEmpty) {
                  return EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No reports yet',
                    message: 'Your campus contributions will appear here.',
                    actionLabel: 'Report your first issue',
                    onAction: () => ReportFormScreen.open(context),
                  );
                }
                if (visible.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching reports',
                    message: 'Try a different keyword or status.',
                  );
                }
                return Column(
                  children: [
                    for (final report in visible)
                      ReportCard(
                        report: report,
                        onTap: () =>
                            ReportDetailsScreen.open(context, report.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => ReportFormScreen.open(context),
              icon: const Icon(Icons.add),
              label: const Text('Report another issue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, ReportStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoicePill(
        label: label,
        selected: _status == status,
        onTap: () => setState(() => _status = status),
      ),
    );
  }
}
