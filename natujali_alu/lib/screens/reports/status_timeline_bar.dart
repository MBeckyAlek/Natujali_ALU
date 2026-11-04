import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/report.dart';

/// Compact horizontal progress: Submitted → Under review → In Progress → Resolved.
class StatusTimelineBar extends StatelessWidget {
  const StatusTimelineBar({super.key, required this.current});

  final ReportStatus current;

  @override
  Widget build(BuildContext context) {
    const steps = ReportStatus.values;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 11),
                color: i <= current.index
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
          _Step(status: steps[i], current: current),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.status, required this.current});

  final ReportStatus status;
  final ReportStatus current;

  @override
  Widget build(BuildContext context) {
    final isDone =
        status.index < current.index || current == ReportStatus.resolved;
    final isCurrent = status == current && !isDone;
    final isReached = status.index <= current.index;

    final Widget circle;
    if (isDone) {
      circle = const CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.check, size: 14, color: Colors.white),
      );
    } else if (isCurrent) {
      circle = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Center(
          child: CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
        ),
      );
    } else {
      circle = const CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.crimsonCard,
      );
    }

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          circle,
          const SizedBox(height: 6),
          Text(
            status.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isReached ? AppColors.primary : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
