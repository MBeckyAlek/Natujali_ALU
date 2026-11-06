import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Rounded selectable pill used for filters and tabs like "All / Open".
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.colors.primary : context.colors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? context.colors.primary : context.colors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : context.colors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
