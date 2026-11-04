import 'package:flutter/material.dart';

/// Page title with an optional red eyebrow label, back button and trailing
/// action, matching the header used throughout the Figma screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.showBack = false,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(eyebrow!.toUpperCase(), style: textTheme.labelSmall),
                Text(title, style: textTheme.headlineSmall),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
