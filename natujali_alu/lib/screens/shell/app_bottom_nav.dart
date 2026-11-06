import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Bottom bar from the design: Home, Reports, a raised Report button, Profile.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onReportPressed,
  });

  /// 0 = Home, 1 = Reports, 2 = Profile.
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _tab(context, 0, Icons.home_outlined, 'Home'),
              _tab(context, 1, Icons.assignment_outlined, 'Reports'),
              Expanded(child: _ReportButton(onPressed: onReportPressed)),
              _tab(context, 2, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final selected = index == currentIndex;
    final color = selected ? context.colors.primary : context.colors.muted;
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Report an issue',
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.colors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.colors.accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 2),
            Text(
              'Report',
              style: TextStyle(
                color: context.colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
