import 'package:flutter/material.dart';

import 'report.dart';

/// A personal badge. Only the student who earned it ever sees it: there is
/// no leaderboard, so reporting stays private.
class Achievement {
  const Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.goal,
  });

  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int goal;

  bool get earned => progress >= goal;
}

/// Every badge with the student's progress towards it, worked out from the
/// reports already loaded. Nothing is stored.
List<Achievement> achievementsFor({
  required String uid,
  required List<Report> allReports,
}) {
  final mine = allReports.where((r) => r.reporterId == uid).toList();
  final resolved = mine.where((r) => r.status == ReportStatus.resolved);
  final buildings = {
    for (final report in mine)
      if (campusBuildings.contains(report.building)) report.building,
  };
  final backed = allReports.where((r) => r.isSupportedBy(uid)).length;

  Achievement badge(
    String title,
    String description,
    IconData icon,
    int progress,
    int goal,
  ) => Achievement(
    title: title,
    description: description,
    icon: icon,
    progress: progress.clamp(0, goal),
    goal: goal,
  );

  return [
    badge(
      'First report',
      'Submit your first report',
      Icons.flag_outlined,
      mine.length,
      1,
    ),
    badge(
      'Problem solver',
      'Have a report resolved',
      Icons.check_circle_outline,
      resolved.length,
      1,
    ),
    badge(
      'Campus guardian',
      'Have 5 reports resolved',
      Icons.shield_outlined,
      resolved.length,
      5,
    ),
    badge(
      'Sharp eye',
      'Have 3 reports with photos resolved',
      Icons.photo_camera_outlined,
      resolved.where((r) => r.photoPath != null).length,
      3,
    ),
    badge(
      'Safety first',
      'Have a safety report resolved',
      Icons.health_and_safety_outlined,
      resolved.where((r) => r.category == ReportCategory.safety).length,
      1,
    ),
    badge(
      'Campus explorer',
      'Report in all ${campusBuildings.length} buildings',
      Icons.apartment_outlined,
      buildings.length,
      campusBuildings.length,
    ),
    badge(
      'Good neighbour',
      'Say "Me too" on 3 reports instead of duplicating them',
      Icons.people_outline,
      backed,
      3,
    ),
  ];
}
