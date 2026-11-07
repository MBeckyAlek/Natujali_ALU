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

  @override
  Future<void> updateStatus(
    String reportId, {
    required ReportStatus status,
    required String note,
    String? assignedTeam,
    ReportPriority? priority,
  }) async {
    await _simulateNetwork();
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) throw StateError('Report $reportId not found');
    final update = StatusUpdate(
      status: status,
      note: note,
      updatedBy:
          assignedTeam ?? _reports[index].assignedTeam ?? campusOperationsName,
      at: DateTime.now(),
    );
    _reports[index] = _reports[index].withStatusUpdate(
      update,
      assignedTeam: assignedTeam,
      priority: priority,
    );
    _emit();
  }

  @override
  Future<void> setSupport(
    String reportId, {
    required String uid,
    required bool support,
  }) async {
    await _simulateNetwork();
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) throw StateError('Report $reportId not found');
    _reports[index] = _reports[index].withSupport(uid, support: support);
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
    ReportPriority? priority,
    List<String> supporters = const [],
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
      staffPriority: priority,
      supporters: supporters,
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
      priority: ReportPriority.urgent,
      supporters: const ['student-2', 'student-3', 'student-4'],
      description:
          'The taps in Social Commons have had no running water since this '
          'morning. Residents on floors 2 and 3 are unable to access water for basic needs.',
      category: ReportCategory.water,
      building: 'Social Commons',
      landmark: '2nd floor washrooms',
      reporterId: me,
      age: const Duration(hours: 2),
      assignedTeam: 'Plumbing',
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
      building: 'Learning Commons',
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
      priority: ReportPriority.low,
      supporters: [me],
      description:
          'One of the chairs in the quiet study area has a cracked leg and wobbles '
          'badly when you sit on it.',
      category: ReportCategory.furniture,
      building: 'Learning Commons',
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
      building: 'Learning Commons',
      landmark: 'Room 204',
      reporterId: me,
      age: const Duration(days: 1),
      assignedTeam: 'IT & AV',
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
      building: 'Enterprise Commons',
      landmark: 'Main staircase',
      reporterId: 'student-3',
      age: const Duration(days: 2),
      assignedTeam: 'Security',
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
          'Security',
          const Duration(days: 2),
        ),
        update(
          ReportStatus.inProgress,
          'A contractor is booked to secure the handrail.',
          'Security',
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
      building: 'Social Commons',
      landmark: 'Outside entrance',
      reporterId: me,
      age: const Duration(days: 3),
      assignedTeam: 'Cleaning',
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
          'Cleaning',
          const Duration(days: 3),
        ),
        update(
          ReportStatus.inProgress,
          'A team is on the way to clear the bins.',
          'Cleaning',
          const Duration(days: 3),
        ),
        update(
          ReportStatus.resolved,
          'A cleaner campus. Thank you! The overflowing bins by the cafeteria have been cleared.',
          'Cleaning',
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
      building: 'Enterprise Commons',
      reporterId: 'student-4',
      age: const Duration(days: 6),
      assignedTeam: 'Facilities',
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
          'Facilities',
          const Duration(days: 5),
        ),
        update(
          ReportStatus.resolved,
          'The roof has been sealed and the bench is dry.',
          'Facilities',
          const Duration(days: 4),
        ),
      ],
    ),
    ..._pastMonthReports(now),
  ];
}

/// About a month of older reports, so the staff dashboard charts have a
/// realistic spread to show. Generated from fixed patterns, not random
/// numbers, so tests see the same data every run.
List<Report> _pastMonthReports(DateTime now) {
  const categories = [
    ReportCategory.facilities,
    ReportCategory.water,
    ReportCategory.sanitation,
    ReportCategory.facilities,
    ReportCategory.electricity,
    ReportCategory.furniture,
    ReportCategory.facilities,
    ReportCategory.safety,
    ReportCategory.water,
    ReportCategory.sanitation,
  ];
  const titles = {
    ReportCategory.facilities: 'Door handle broken',
    ReportCategory.water: 'Leaking tap',
    ReportCategory.electricity: 'Socket not working',
    ReportCategory.furniture: 'Wobbly desk',
    ReportCategory.sanitation: 'Washroom needs cleaning',
    ReportCategory.safety: 'Fire exit sign unlit',
  };
  const teams = {
    ReportCategory.facilities: 'Facilities',
    ReportCategory.water: 'Plumbing',
    ReportCategory.electricity: 'Electrical',
    ReportCategory.furniture: 'Facilities',
    ReportCategory.sanitation: 'Cleaning',
    ReportCategory.safety: 'Security',
  };

  Report sample(int i) {
    final category = categories[i % categories.length];
    final team = teams[category]!;
    final createdAt = now.subtract(
      Duration(days: 2 + (i * 11) % 28, hours: (i * 5) % 12),
    );
    final fixTime = Duration(hours: 8 + (i * 13) % 80);
    // Every sixth report is still open, as are fixes that would end in the future.
    final isResolved = i % 6 != 0 && createdAt.add(fixTime).isBefore(now);
    final history = [
      StatusUpdate(
        status: ReportStatus.submitted,
        note: 'Your report is safely submitted. We will keep you updated.',
        updatedBy: 'Natujali',
        at: createdAt,
      ),
      StatusUpdate(
        status: ReportStatus.underReview,
        note: '$team has the report and will take a look.',
        updatedBy: team,
        at: createdAt.add(const Duration(hours: 3)),
      ),
      StatusUpdate(
        status: ReportStatus.inProgress,
        note: 'Work on this has started.',
        updatedBy: team,
        at: createdAt.add(fixTime ~/ 2),
      ),
      if (isResolved)
        StatusUpdate(
          status: ReportStatus.resolved,
          note: 'This has been fixed. Thank you for reporting it.',
          updatedBy: team,
          at: createdAt.add(fixTime),
        ),
    ];
    final number = 900 + i;
    return Report(
      id: 'report-$number',
      reference: 'NJ-$number',
      title: titles[category]!,
      description:
          'Sample report used to fill the staff dashboard with realistic '
          'activity from the past month.',
      category: category,
      building: campusBuildings[i % campusBuildings.length],
      landmark: '',
      status: history.last.status,
      reporterId: 'student-${5 + i % 4}',
      assignedTeam: team,
      createdAt: createdAt,
      updatedAt: history.last.at,
      history: history,
    );
  }

  return [for (var i = 0; i < 36; i++) sample(i)];
}
