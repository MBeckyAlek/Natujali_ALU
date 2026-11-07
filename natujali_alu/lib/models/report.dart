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

/// How quickly staff aim to resolve a report, measured from when it was
/// submitted. Staff set it; until then it comes from the category.
enum ReportPriority {
  urgent('Urgent', Duration(hours: 4)),
  high('High', Duration(hours: 24)),
  normal('Normal', Duration(days: 3)),
  low('Low', Duration(days: 7));

  const ReportPriority(this.label, this.target);

  final String label;
  final Duration target;

  /// Safety issues start as high priority; everything else as normal.
  static ReportPriority defaultFor(ReportCategory category) =>
      category == ReportCategory.safety ? high : normal;
}

/// The three main campus buildings. Each has several floors, so students
/// say where inside the building in the floor/room field and description.
const campusBuildings = [
  'Learning Commons',
  'Enterprise Commons',
  'Social Commons',
];

/// Shown as the author of staff updates when no team is assigned.
const campusOperationsName = 'Campus operations';

/// Teams staff can assign a report to. Shown to students as "Assigned to".
const campusTeams = [
  'Facilities',
  'Electrical',
  'Plumbing',
  'Cleaning',
  'Security',
  'IT & AV',
  'Grounds',
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
    this.staffPriority,
    this.supporters = const [],
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

  /// Priority chosen by staff, or null if they haven't set one yet.
  final ReportPriority? staffPriority;

  /// Students who tapped "Me too" because the issue affects them as well.
  final List<String> supporters;

  ReportPriority get priority =>
      staffPriority ?? ReportPriority.defaultFor(category);

  /// When staff aim to have this resolved, based on its priority.
  DateTime get dueAt => createdAt.add(priority.target);

  bool isOverdue(DateTime now) => status.isOpen && now.isAfter(dueAt);

  bool isSupportedBy(String? uid) => uid != null && supporters.contains(uid);

  String get location => landmark.isEmpty ? building : '$building · $landmark';

  StatusUpdate get latestUpdate => history.last;

  /// Students may only change their own report before staff pick it up.
  bool canBeEditedBy(String? uid) =>
      uid == reporterId && status == ReportStatus.submitted;

  /// Returns a copy moved to [update]'s status, with the update added to
  /// the history.
  Report withStatusUpdate(
    StatusUpdate update, {
    String? assignedTeam,
    ReportPriority? priority,
  }) {
    return Report(
      id: id,
      reference: reference,
      title: title,
      description: description,
      category: category,
      building: building,
      landmark: landmark,
      photoPath: photoPath,
      status: update.status,
      reporterId: reporterId,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      staffPriority: priority ?? staffPriority,
      supporters: supporters,
      createdAt: createdAt,
      updatedAt: update.at,
      history: [...history, update],
    );
  }

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
      staffPriority: staffPriority,
      supporters: supporters,
      createdAt: createdAt,
      updatedAt: updatedAt,
      history: history,
    );
  }

  /// Returns a copy with [uid] added to or removed from the supporters.
  Report withSupport(String uid, {required bool support}) {
    return Report(
      id: id,
      reference: reference,
      title: title,
      description: description,
      category: category,
      building: building,
      landmark: landmark,
      photoPath: photoPath,
      status: status,
      reporterId: reporterId,
      assignedTeam: assignedTeam,
      staffPriority: staffPriority,
      supporters: support
          ? {...supporters, uid}.toList()
          : supporters.where((s) => s != uid).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      history: history,
    );
  }
}
