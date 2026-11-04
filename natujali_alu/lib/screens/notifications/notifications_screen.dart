import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/report.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/choice_pill.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/screen_header.dart';
import '../reports/report_details_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final readAt = ref.watch(notificationsReadAtProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final visible = _unreadOnly
        ? notifications.where((n) => isUnread(n, readAt)).toList()
        : notifications;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader(title: 'Notifications', showBack: true),
            Row(
              children: [
                ChoicePill(
                  label: 'All',
                  selected: !_unreadOnly,
                  onTap: () => setState(() => _unreadOnly = false),
                ),
                const SizedBox(width: 8),
                ChoicePill(
                  label: 'Unread · $unreadCount',
                  selected: _unreadOnly,
                  onTap: () => setState(() => _unreadOnly = true),
                ),
                const Spacer(),
                TextButton(
                  onPressed: unreadCount == 0
                      ? null
                      : () => ref
                            .read(notificationsReadAtProvider.notifier)
                            .markAllRead(),
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (visible.isEmpty)
              EmptyState(
                icon: Icons.notifications_none,
                title: _unreadOnly ? "You're all caught up" : 'No updates yet',
                message: 'Status changes on your reports will appear here.',
              )
            else
              for (final notification in visible)
                _NotificationCard(
                  notification: notification,
                  unread: isUnread(notification, readAt),
                ),
            const SizedBox(height: 8),
            const InfoBanner(
              message: 'Only updates about your own reports appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.unread});

  final ReportNotification notification;
  final bool unread;

  static (IconData, String) _iconAndTitle(ReportStatus status) {
    return switch (status) {
      ReportStatus.submitted => (Icons.send_outlined, 'Report received'),
      ReportStatus.underReview => (
        Icons.assignment_turned_in_outlined,
        'Your report is under review',
      ),
      ReportStatus.inProgress => (
        Icons.build_outlined,
        'Your report is in progress',
      ),
      ReportStatus.resolved => (
        Icons.check_circle_outline,
        'Issue resolved. Thank you!',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final update = notification.update;
    final report = notification.report;
    final (icon, title) = _iconAndTitle(update.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: unread ? AppColors.crimsonCard : AppColors.surface,
        onTap: () => ReportDetailsScreen.open(context, report.id),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.title}: ${update.note}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${report.reference} · ${formatShortDateTime(update.at)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (unread)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
