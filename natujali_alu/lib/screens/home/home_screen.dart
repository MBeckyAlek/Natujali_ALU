import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/announcement_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/notification_providers.dart';
import '../../providers/report_providers.dart';
import '../../widgets/announcement_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/report_card.dart';
import '../../widgets/report_summary_row.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_header.dart';
import '../notifications/notifications_screen.dart';
import '../report_form/report_form_screen.dart';
import '../rewards/rewards_screen.dart';
import '../reports/my_reports_screen.dart';
import '../reports/report_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myReports = ref.watch(myReportsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final now = DateTime.now();
    final announcements =
        (ref.watch(activeAnnouncementsProvider).value ?? const []).where(
          (a) => a.isActive(now),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ScreenHeader(
            eyebrow: 'African Leadership University',
            title: 'Hello, ${user?.firstName ?? 'there'} 👋',
            trailing: IconButton.filledTonal(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_none),
              ),
            ),
          ),
          for (final announcement in announcements)
            AnnouncementBanner(announcement: announcement),
          _ReportPromptCard(onReport: () => ReportFormScreen.open(context)),
          const SizedBox(height: 12),
          CoinBalanceCard(
            summary: ref.watch(coinSummaryProvider),
            onTap: () => RewardsScreen.open(context),
          ),
          SectionHeader(
            title: 'Report summary',
            actionLabel: 'See all',
            onAction: () => MyReportsScreen.open(context),
          ),
          ReportSummaryRow(reports: myReports.value ?? const []),
          SectionHeader(
            title: 'Recent reports',
            actionLabel: 'See all',
            onAction: () => MyReportsScreen.open(context),
          ),
          myReports.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: "Couldn't load your reports",
              message: 'Check your connection and try again.',
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No reports yet',
                  message: 'Your campus contributions will appear here.',
                  actionLabel: 'Report your first issue',
                  onAction: () => ReportFormScreen.open(context),
                );
              }
              return Column(
                children: [
                  for (final report in reports.take(3))
                    ReportCard(
                      report: report,
                      onTap: () => ReportDetailsScreen.open(context, report.id),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportPromptCard extends StatelessWidget {
  const _ReportPromptCard({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'See an issue\non campus?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Report it and help improve our learning environment.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.apartment_rounded,
                size: 72,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: context.colors.primary,
            ),
            onPressed: onReport,
            icon: const Icon(Icons.add),
            label: const Text('Report an issue'),
          ),
        ],
      ),
    );
  }
}
