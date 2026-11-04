import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/report.dart';

/// Square preview for a report: its photo if it has one, otherwise the
/// category icon.
class ReportThumbnail extends StatelessWidget {
  const ReportThumbnail({super.key, required this.report, this.size = 64});

  final Report report;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.crimsonCard,
      child: Icon(
        report.category.icon,
        color: AppColors.primary,
        size: size * 0.42,
      ),
    );
    final path = report.photoPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: path == null
            ? placeholder
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
