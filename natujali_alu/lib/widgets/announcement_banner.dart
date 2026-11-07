import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/announcement.dart';
import 'info_banner.dart';

/// One staff announcement as a warning banner, e.g. on Home or above the
/// report form when the student picks the affected building.
class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (announcement.message.isNotEmpty) announcement.message,
      '${announcement.audience} · until '
          '${formatShortDateTime(announcement.expiresAt)}',
    ].join('\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InfoBanner(
        tone: BannerTone.warning,
        icon: Icons.campaign_outlined,
        title: announcement.title,
        message: details,
      ),
    );
  }
}
