import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../models/report_insights.dart';
import '../../providers/announcement_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/report_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_header.dart';
import 'activity_chart.dart';
import 'announcements_screen.dart';
import 'review_incident_screen.dart';

/// Staff home: workload at a glance, trends and problem areas. Tapping a
/// number opens the Reports tab already filtered.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onOpenReports});

  /// Switches the staff shell to the Reports tab.
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final reports = ref.watch(reportsProvider);

    final announcementCount =
        ref.watch(activeAnnouncementsProvider).value?.length ?? 0;

    void openQueue(
      QueueTab tab, {
      ReportCategory? category,
      bool overdueOnly = false,
    }) {
      ref
          .read(staffQueueFilterProvider.notifier)
          .show(tab, category: category, overdueOnly: overdueOnly);
      onOpenReports();
    }

    return SafeArea(
      child: RefreshIndicator(
        // Data is live already; this just reassures people who pull to refresh.
        onRefresh: () => ref.refresh(reportsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ScreenHeader(
              eyebrow: 'Campus operations',
              title: 'Hello, ${user?.firstName ?? 'there'}',
            ),
            reports.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const EmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load reports",
                message: 'Check your connection and try again.',
              ),
              data: (all) =>
                  _buildContent(context, all, openQueue, announcementCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Report> all,
    void Function(QueueTab tab, {ReportCategory? category, bool overdueOnly})
    openQueue,
    int announcementCount,
  ) {
    final overdue = overdueReports(all);
    final backed = mostBackedReports(all).take(3).toList();
    final insights = ReportInsights(all);
    final average = insights.averageResolutionTime;
    final longestWait = insights.longestOpenWait;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatGrid(reports: all, onSelected: openQueue),
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoBanner(
            tone: BannerTone.warning,
            icon: Icons.schedule,
            title:
                '${overdue.length} ${overdue.length == 1 ? 'report is' : 'reports are'} overdue',
            message:
                'Past the time target for their priority '
                '(urgent 4 h, high 1 day, normal 3 days, low 1 week).',
            actionLabel: 'Show overdue reports',
            onAction: () => openQueue(QueueTab.open, overdueOnly: true),
          ),
        ],
        const SizedBox(height: 12),
        AppCard(
          onTap: () => AnnouncementsScreen.open(context),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: context.colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Announcements',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      announcementCount == 0
                          ? 'Tell students about known issues so they '
                                "don't report them again"
                          : '$announcementCount active',
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.muted),
            ],
          ),
        ),
        if (backed.isNotEmpty) ...[
          const SectionHeader(title: 'Affecting the most students'),
          for (final report in backed)
            ReportCard(
              report: report,
              forStaff: true,
              onTap: () => ReviewIncidentScreen.open(context, report.id),
            ),
        ],
        const SectionHeader(title: 'Activity'),
        ActivityChart(insights: insights),
        const SizedBox(height: 12),
        Row(
          children: [
            _Metric(
              value: average == null ? '–' : formatDuration(average),
              label: 'Avg. time to resolve',
            ),
            const SizedBox(width: 10),
            _Metric(
              value: '${insights.resolvedThisWeek}',
              label: 'Resolved in 7 days',
            ),
            const SizedBox(width: 10),
            _Metric(
              value: longestWait == null ? '–' : formatDuration(longestWait),
              label: 'Longest open wait',
            ),
          ],
        ),
        const SectionHeader(title: 'Reports by category'),
        _CategoryBars(
          counts: insights.countByCategory,
          onSelected: (category) => openQueue(QueueTab.all, category: category),
        ),
      ],
    );
  }
}

/// One headline number in the row under the chart.
class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: c.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bars, one per category, largest first. Tap a row to see
/// those reports.
class _CategoryBars extends StatelessWidget {
  const _CategoryBars({required this.counts, required this.onSelected});

  final List<(ReportCategory, int)> counts;
  final ValueChanged<ReportCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (counts.isEmpty) {
      return Text('No reports yet.', style: TextStyle(color: c.muted));
    }
    final largest = counts.first.$2;

    return AppCard(
      child: Column(
        children: [
          for (final (category, count) in counts)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(category),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(category.icon, size: 18, color: c.muted),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 84,
                      child: Text(
                        category.label,
                        style: TextStyle(color: c.ink, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: count / largest,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: c.chartOpened,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

/// Four tappable counters, one per status.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.reports, required this.onSelected});

  final List<Report> reports;
  final ValueChanged<QueueTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    int count(ReportStatus status) =>
        reports.where((r) => r.status == status).length;

    final tiles = [
      (QueueTab.submitted, count(ReportStatus.submitted), c.amber, c.amberText),
      (
        QueueTab.underReview,
        count(ReportStatus.underReview),
        c.purple,
        c.purpleText,
      ),
      (
        QueueTab.inProgress,
        count(ReportStatus.inProgress),
        c.accentTint,
        c.accent,
      ),
      (QueueTab.resolved, count(ReportStatus.resolved), c.green, c.greenText),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        for (final (tab, value, background, foreground) in tiles)
          Material(
            color: background,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelected(tab),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tab.label,
                      style: TextStyle(color: foreground, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
