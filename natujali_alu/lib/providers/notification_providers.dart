import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import 'report_providers.dart';

/// A status change on one of the student's own reports.
class ReportNotification {
  const ReportNotification({required this.report, required this.update});

  final Report report;
  final StatusUpdate update;
}

/// Notifications are built from the status history of the student's own
/// reports, so there is no separate collection to keep in sync.
final notificationsProvider = Provider<List<ReportNotification>>((ref) {
  final reports = ref.watch(myReportsProvider).value ?? const [];
  final items = [
    for (final report in reports)
      for (final update in report.history)
        ReportNotification(report: report, update: update),
  ];
  items.sort((a, b) => b.update.at.compareTo(a.update.at));
  return items;
});

/// When the student last pressed "Mark all read". Null means never.
class NotificationsReadNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void markAllRead() => state = DateTime.now();
}

final notificationsReadAtProvider =
    NotifierProvider<NotificationsReadNotifier, DateTime?>(
      NotificationsReadNotifier.new,
    );

bool isUnread(ReportNotification notification, DateTime? readAt) =>
    readAt == null || notification.update.at.isAfter(readAt);

final unreadCountProvider = Provider<int>((ref) {
  final readAt = ref.watch(notificationsReadAtProvider);
  return ref
      .watch(notificationsProvider)
      .where((notification) => isUnread(notification, readAt))
      .length;
});
