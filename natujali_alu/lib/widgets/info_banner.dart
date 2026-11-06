import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum BannerTone { info, warning }

/// Tinted message box used for hints, privacy notes, warnings and errors.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
    this.tone = BannerTone.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final IconData icon;
  final BannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == BannerTone.warning;
    final background = isWarning
        ? context.colors.amber
        : context.colors.primaryTint;
    final foreground = isWarning
        ? context.colors.amberText
        : context.colors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null)
                  GestureDetector(
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
