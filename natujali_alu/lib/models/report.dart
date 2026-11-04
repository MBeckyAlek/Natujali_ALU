import 'package:flutter/material.dart';

enum ReportCategory {
  facilities('Facilities', Icons.build_outlined),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_outlined),
  furniture('Furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.delete_outline),
  safety('Safety', Icons.shield_outlined);

  const ReportCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The order of these values is the order a report moves through.
enum ReportStatus {
  submitted('Submitted'),
  underReview('Under review'),
  inProgress('In Progress'),
  resolved('Resolved');

  const ReportStatus(this.label);

  final String label;

  bool get isOpen => this != ReportStatus.resolved;
}

/// Areas students can pick when reporting. Replace with the real campus list.
const campusBuildings = [
  'Main Building',
  'Lecture Block A',
  'Lecture Block B',
  'Library',
  'Innovation Lab',
  'Student Residence',
  'Cafeteria',
  'Sports Ground',
  'Car Park',
  'Other',
];

/// One entry in a report's status history. Entries are only ever added,
/// so the history doubles as an audit trail and as the student's
/// notifications feed.
class StatusUpdate {
  const StatusUpdate({
    required this.status,
    required this.note,
    required this.updatedBy,
    required this.at,
  });

  final ReportStatus status;
  final String note;
  final String updatedBy;
  final DateTime at;
}

/// The fields a student fills in on the report form, used for both
/// creating and editing a report.
class ReportInput {
  const ReportInput({
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.landmark,
    this.photoPath,
  });

  final String title;
  final String description;
  final ReportCategory category;
  final String building;
  final String landmark;
  final String? photoPath;
}

class Report {
  const Report({
    required this.id,
    required this.reference,
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.landmark,
    required this.status,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    this.photoPath,
    this.assignedTeam,
  });

  final String id;

  /// Short, human-friendly ID shown to students, e.g. "NJ-2031".
  final String reference;
  final String title;
  final String description;
  final ReportCategory category;
  final String building;
  final String landmark;
  final ReportStatus status;
  final String reporterId;
  final String? photoPath;
  final String? assignedTeam;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusUpdate> history;

  String get location => landmark.isEmpty ? building : '$building · $landmark';

  StatusUpdate get latestUpdate => history.last;

  /// Students may only change their own report before staff pick it up.
  bool canBeEditedBy(String? uid) =>
      uid == reporterId && status == ReportStatus.submitted;

  /// Returns a copy with the student-editable fields replaced.
  Report withDetails(ReportInput input, DateTime updatedAt) {
    return Report(
      id: id,
      reference: reference,
      title: input.title,
      description: input.description,
      category: input.category,
      building: input.building,
      landmark: input.landmark,
      photoPath: input.photoPath,
      status: status,
      reporterId: reporterId,
      assignedTeam: assignedTeam,
      createdAt: createdAt,
      updatedAt: updatedAt,
      history: history,
    );
  }
}
