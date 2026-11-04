import 'dart:async';

import '../models/app_user.dart';
import '../models/report.dart';
import 'fake_auth_repository.dart';
import 'report_repository.dart';

/// In-memory stand-in for Firestore, seeded with sample reports so every
/// screen has something to show. Data resets when the app restarts.
class FakeReportRepository implements ReportRepository {
  FakeReportRepository() : _reports = _seedReports();

  final List<Report> _reports;
  final _controller = StreamController<List<Report>>.broadcast();
  int _nextReference = 2032;

  @override
  Stream<List<Report>> watchReports() async* {
    yield _sortedReports();
    yield* _controller.stream;
  }

  @override
  Future<Report> createReport(
    ReportInput input, {
    required AppUser reporter,
  }) async {
    await _simulateNetwork();
    final now = DateTime.now();
    final number = _nextReference++;
    final report = Report(
      id: 'report-$number',
      reference: 'NJ-$number',
      title: input.title,
      description: input.description,
      category: input.category,
      building: input.building,
      landmark: input.landmark,
      photoPath: input.photoPath,
      status: ReportStatus.submitted,
      reporterId: reporter.uid,
      createdAt: now,
      updatedAt: now,
      history: [
        StatusUpdate(
          status: ReportStatus.submitted,
          note: 'Your report is safely submitted. We will keep you updated.',
          updatedBy: 'Natujali',
          at: now,
        ),
      ],
    );
    _reports.add(report);
    _emit();
    return report;
  }

  @override
  Future<void> updateReport(String reportId, ReportInput input) async {
    await _simulateNetwork();
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) throw StateError('Report $reportId not found');
    _reports[index] = _reports[index].withDetails(input, DateTime.now());
    _emit();
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await _simulateNetwork();
    _reports.removeWhere((report) => report.id == reportId);
    _emit();
  }

  List<Report> _sortedReports() =>
      [..._reports]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void _emit() => _controller.add(_sortedReports());

  Future<void> _simulateNetwork() =>
      Future.delayed(const Duration(milliseconds: 800));
}

List<Report> _seedReports() {
  final now = DateTime.now();
  final me = FakeAuthRepository.demoStudent.uid;

  Report report({
    required int number,
    required String title,
    required String description,
    required ReportCategory category,
    required String building,
    String landmark = '',
    required String reporterId,
    required Duration age,
    required List<StatusUpdate> history,
    String? assignedTeam,
  }) {
    return Report(
      id: 'report-$number',
      reference: 'NJ-$number',
      title: title,
      description: description,
      category: category,
      building: building,
      landmark: landmark,
      status: history.last.status,
      reporterId: reporterId,
      assignedTeam: assignedTeam,
      createdAt: now.subtract(age),
      updatedAt: history.last.at,
      history: history,
    );
  }

  StatusUpdate update(
    ReportStatus status,
    String note,
    String by,
    Duration ago,
  ) {
    return StatusUpdate(
      status: status,
      note: note,
      updatedBy: by,
      at: now.subtract(ago),
    );
  }

  const received = 'Your report is safely submitted. We will keep you updated.';

  return [
    report(
      number: 2031,
      title: 'Water shortage',
      description:
          'The taps in Student Residence have had no running water since this '
          'morning. Residents on floors 2 and 3 are unable to access water for basic needs.',
      category: ReportCategory.water,
      building: 'Student Residence',
      landmark: 'Block B',
      reporterId: me,
      age: const Duration(hours: 2),
      assignedTeam: 'Facilities · Water & Utilities',
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(hours: 2),
        ),
        update(
          ReportStatus.underReview,
          'Facilities verified the location and issue.',
          'Jordan Lee · Campus Facilities',
          const Duration(hours: 1, minutes: 20),
        ),
        update(
          ReportStatus.inProgress,
          'The Water & Utilities team is investigating the loss of water supply '
              'in Block B. Repairs are in progress.',
          'Jordan Lee · Campus Facilities',
          const Duration(minutes: 25),
        ),
      ],
    ),
    report(
      number: 2029,
      title: 'Flickering corridor lights',
      description:
          'The lights along the ground floor corridor keep flickering on and off, '
          'which makes it hard to see in the evening.',
      category: ReportCategory.electricity,
      building: 'Library',
      landmark: 'Ground floor corridor',
      reporterId: me,
      age: const Duration(minutes: 40),
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(minutes: 40),
        ),
      ],
    ),
    report(
      number: 2027,
      title: 'Broken chair in study area',
      description:
          'One of the chairs in the quiet study area has a cracked leg and wobbles '
          'badly when you sit on it.',
      category: ReportCategory.furniture,
      building: 'Library',
      landmark: 'Quiet study area',
      reporterId: 'student-2',
      age: const Duration(hours: 5),
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(hours: 5),
        ),
      ],
    ),
    report(
      number: 1041,
      title: 'Broken classroom projector',
      description:
          'The projector in Room 204 does not turn on. Lecturers have had to '
          'cancel slides for the last two classes.',
      category: ReportCategory.facilities,
      building: 'Lecture Block B',
      landmark: 'Room 204',
      reporterId: me,
      age: const Duration(days: 1),
      assignedTeam: 'IT Support',
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(days: 1),
        ),
        update(
          ReportStatus.underReview,
          'IT Support has the report and will inspect the projector.',
          'Grace M. · IT Support',
          const Duration(hours: 20),
        ),
      ],
    ),
    report(
      number: 1033,
      title: 'Loose handrail on main stairs',
      description:
          'The handrail on the main staircase between the first and second floor '
          'is loose and moves when people lean on it.',
      category: ReportCategory.safety,
      building: 'Main Building',
      landmark: 'Main staircase',
      reporterId: 'student-3',
      age: const Duration(days: 2),
      assignedTeam: 'Campus Safety',
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(days: 2),
        ),
        update(
          ReportStatus.underReview,
          'Campus Safety has taped off the area.',
          'Campus Safety',
          const Duration(days: 2),
        ),
        update(
          ReportStatus.inProgress,
          'A contractor is booked to secure the handrail.',
          'Campus Safety',
          const Duration(days: 1),
        ),
      ],
    ),
    report(
      number: 1018,
      title: 'Overflowing bin',
      description:
          'The bins outside the cafeteria are overflowing and rubbish is spreading '
          'across the walkway.',
      category: ReportCategory.sanitation,
      building: 'Cafeteria',
      landmark: 'Outside entrance',
      reporterId: me,
      age: const Duration(days: 3),
      assignedTeam: 'Cleaning Services',
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(days: 3),
        ),
        update(
          ReportStatus.underReview,
          'Cleaning Services has been notified.',
          'Cleaning Services',
          const Duration(days: 3),
        ),
        update(
          ReportStatus.inProgress,
          'A team is on the way to clear the bins.',
          'Cleaning Services',
          const Duration(days: 3),
        ),
        update(
          ReportStatus.resolved,
          'A cleaner campus. Thank you! The overflowing bins by the cafeteria have been cleared.',
          'Cleaning Services',
          const Duration(days: 2, hours: 20),
        ),
      ],
    ),
    report(
      number: 1009,
      title: 'Leaking roof above workbench',
      description:
          'Water drips from the ceiling onto the electronics workbench whenever '
          'it rains. We have put a bucket under it for now.',
      category: ReportCategory.facilities,
      building: 'Innovation Lab',
      reporterId: 'student-4',
      age: const Duration(days: 6),
      assignedTeam: 'Facilities · Maintenance',
      history: [
        update(
          ReportStatus.submitted,
          received,
          'Natujali',
          const Duration(days: 6),
        ),
        update(
          ReportStatus.inProgress,
          'Roofers are sealing the damaged section.',
          'Facilities · Maintenance',
          const Duration(days: 5),
        ),
        update(
          ReportStatus.resolved,
          'The roof has been sealed and the bench is dry.',
          'Facilities · Maintenance',
          const Duration(days: 4),
        ),
      ],
    ),
  ];
}
