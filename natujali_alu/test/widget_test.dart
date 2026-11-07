import 'package:flutter_test/flutter_test.dart';
import 'package:natujali_alu/core/utils/validators.dart';
import 'package:natujali_alu/data/announcement_repository.dart';
import 'package:natujali_alu/data/fake_auth_repository.dart';
import 'package:natujali_alu/data/fake_report_repository.dart';
import 'package:natujali_alu/models/achievements.dart';
import 'package:natujali_alu/models/report.dart';
import 'package:natujali_alu/models/report_filter.dart';
import 'package:natujali_alu/models/report_insights.dart';
import 'package:natujali_alu/models/rewards.dart';
import 'package:natujali_alu/providers/staff_providers.dart';

void main() {
  group('Validators', () {
    test('student registration only accepts @alustudent.com', () {
      expect(Validators.studentEmail('a.hassan@alustudent.com'), isNull);
      expect(Validators.studentEmail('amina@gmail.com'), isNotNull);
      expect(Validators.studentEmail('staff@alueducation.com'), isNotNull);
    });

    test('sign in accepts student and staff ALU emails', () {
      expect(Validators.aluEmail('a.hassan@alustudent.com'), isNull);
      expect(Validators.aluEmail('j.lee@alueducation.com'), isNull);
      expect(Validators.aluEmail('amina@gmail.com'), isNotNull);
    });

    test('password needs 8+ characters and a number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('nodigitshere'), isNotNull);
      expect(Validators.password('password1'), isNull);
    });

    test('description must be 20 to 1000 characters', () {
      expect(Validators.reportDescription('Too short'), isNotNull);
      expect(
        Validators.reportDescription('The tap in Block B is leaking.'),
        isNull,
      );
      expect(Validators.reportDescription('a' * 1001), isNotNull);
    });
  });

  group('ReportFilter', () {
    test('filters by status, category and search text', () async {
      final reports = await FakeReportRepository().watchReports().first;

      final resolved = ReportFilter(statuses: {ReportStatus.resolved})
          .apply(reports);
      expect(resolved.every((r) => r.status == ReportStatus.resolved), isTrue);

      final water = ReportFilter(categories: {ReportCategory.water})
          .apply(reports);
      expect(water.map((r) => r.title), contains('Water shortage'));

      final search = const ReportFilter(query: 'nj-2031').apply(reports);
      expect(search.single.reference, 'NJ-2031');
    });

    test('filters by building and month submitted', () async {
      final reports = await FakeReportRepository().watchReports().first;

      final social = const ReportFilter(building: 'Social Commons')
          .apply(reports);
      expect(social, isNotEmpty);
      expect(social.every((r) => r.building == 'Social Commons'), isTrue);

      final months = reportMonths(reports);
      expect(
        months,
        orderedEquals([...months]..sort((a, b) => b.compareTo(a))),
      );
      final inMonth = ReportFilter(month: months.first).apply(reports);
      expect(inMonth, isNotEmpty);
      expect(
        inMonth.every((r) => monthOf(r.createdAt) == months.first),
        isTrue,
      );
    });

    test('staff month filter covers the whole month', () {
      final october = DateTime(2026, 10);
      final filter = StaffQueueFilter(
        tab: QueueTab.all,
        from: october,
        to: DateTime(2026, 10, 31),
      );
      expect(filter.month, october);
      expect(
        StaffQueueFilter(from: october, to: DateTime(2026, 10, 15)).month,
        isNull,
      );
    });
  });

  group('FakeReportRepository', () {
    test('create, update and delete are reflected in the stream', () async {
      final repository = FakeReportRepository();
      const input = ReportInput(
        title: 'Broken door',
        description: 'The library side door does not close properly.',
        category: ReportCategory.facilities,
        building: 'Learning Commons',
        landmark: '',
      );

      final created = await repository.createReport(
        input,
        reporter: FakeAuthRepository.demoStudent,
      );
      expect(created.status, ReportStatus.submitted);
      var reports = await repository.watchReports().first;
      expect(reports.first.id, created.id);

      await repository.updateReport(
        created.id,
        const ReportInput(
          title: 'Broken library door',
          description: 'The library side door does not close properly.',
          category: ReportCategory.facilities,
          building: 'Learning Commons',
          landmark: 'Side entrance',
        ),
      );
      reports = await repository.watchReports().first;
      expect(reports.first.title, 'Broken library door');

      await repository.deleteReport(created.id);
      reports = await repository.watchReports().first;
      expect(reports.any((r) => r.id == created.id), isFalse);
    });
  });

  group('Rewards', () {
    test('coins are earned only once staff resolve a report', () async {
      final repository = FakeReportRepository();
      final open = (await repository.watchReports().first).firstWhere(
        (r) => r.status == ReportStatus.submitted,
      );
      expect(coinsFor(open), 0);

      await repository.updateStatus(
        open.id,
        status: ReportStatus.resolved,
        note: 'Fixed by the facilities team today.',
      );
      final resolved = (await repository.watchReports().first).firstWhere(
        (r) => r.id == open.id,
      );
      final expected =
          coinsPerResolvedReport +
          (resolved.photoPath != null ? photoBonusCoins : 0);
      expect(coinsFor(resolved), expected);
    });

    test('summary adds up resolved reports and counts open ones', () async {
      final reports = await FakeReportRepository().watchReports().first;
      final summary = CoinSummary(reports);

      final resolvedCount = reports
          .where((r) => r.status == ReportStatus.resolved)
          .length;
      expect(summary.entries.length, resolvedCount);
      expect(
        summary.balance,
        reports.fold<int>(0, (sum, r) => sum + coinsFor(r)),
      );
      expect(summary.pendingReports, reports.length - resolvedCount);
      for (var i = 1; i < summary.entries.length; i++) {
        expect(
          summary.entries[i - 1].earnedAt.isBefore(summary.entries[i].earnedAt),
          isFalse,
        );
      }
    });
  });

  group('Me too', () {
    test('a student can add and remove their own support', () async {
      final repository = FakeReportRepository();
      const uid = 'student-9';
      final report = (await repository.watchReports().first).firstWhere(
        (r) => r.status.isOpen && r.supporters.isEmpty,
      );

      await repository.setSupport(report.id, uid: uid, support: true);
      // Saying it twice still counts once.
      await repository.setSupport(report.id, uid: uid, support: true);
      var updated = (await repository.watchReports().first).firstWhere(
        (r) => r.id == report.id,
      );
      expect(updated.supporters, [uid]);
      expect(updated.isSupportedBy(uid), isTrue);

      await repository.setSupport(report.id, uid: uid, support: false);
      updated = (await repository.watchReports().first).firstWhere(
        (r) => r.id == report.id,
      );
      expect(updated.supporters, isEmpty);
    });

    test('most backed reports come first and skip resolved ones', () async {
      final reports = await FakeReportRepository().watchReports().first;
      final backed = mostBackedReports(reports);

      expect(backed.first.reference, 'NJ-2031');
      expect(backed.every((r) => r.status.isOpen), isTrue);
    });
  });

  group('Badges', () {
    test('progress comes from the student\'s own reports', () async {
      final reports = await FakeReportRepository().watchReports().first;
      final badges = achievementsFor(
        uid: FakeAuthRepository.demoStudent.uid,
        allReports: reports,
      );
      Achievement named(String title) =>
          badges.firstWhere((b) => b.title == title);

      expect(named('First report').earned, isTrue);
      expect(named('Problem solver').earned, isTrue);
      // The demo student backed one report in the sample data.
      expect(named('Good neighbour').progress, 1);
      expect(named('Good neighbour').earned, isFalse);
      expect(badges.every((b) => b.progress <= b.goal), isTrue);
    });
  });

  group('Announcements', () {
    test('posted notices show until taken down', () async {
      final repository = FakeAnnouncementRepository();
      await repository.post(
        title: 'Water off on the 2nd floor',
        message: 'Plumbing work until 4 pm.',
        building: 'Social Commons',
        postedBy: 'Joseph Mensah',
        duration: const Duration(hours: 2),
      );
      final active = await repository.watchActive().first;
      expect(active.single.appliesTo('Social Commons'), isTrue);
      expect(active.single.appliesTo('Learning Commons'), isFalse);

      await repository.remove(active.single.id);
      expect(await repository.watchActive().first, isEmpty);
    });
  });

  group('Staff', () {
    test('status update moves the report and adds to its history', () async {
      final repository = FakeReportRepository();
      final before = (await repository.watchReports().first).firstWhere(
        (r) => r.status == ReportStatus.submitted,
      );

      await repository.updateStatus(
        before.id,
        status: ReportStatus.underReview,
        note: 'We have seen this and are checking.',
        assignedTeam: 'Electrical',
      );

      final after = (await repository.watchReports().first).firstWhere(
        (r) => r.id == before.id,
      );
      expect(after.status, ReportStatus.underReview);
      expect(after.assignedTeam, 'Electrical');
      expect(after.history.length, before.history.length + 1);
      expect(after.latestUpdate.updatedBy, 'Electrical');
    });

    test('open queue lists the soonest due reports first', () async {
      final reports = await FakeReportRepository().watchReports().first;
      final queue = QueueTab.open.sort(
        reports.where(QueueTab.open.matches).toList(),
      );

      expect(queue.every((r) => r.status.isOpen), isTrue);
      for (var i = 1; i < queue.length; i++) {
        expect(queue[i - 1].dueAt.isAfter(queue[i].dueAt), isFalse);
      }
    });

    test('priority defaults by category and sets the due time', () async {
      final repository = FakeReportRepository();
      final report = (await repository.watchReports().first).firstWhere(
        (r) => r.status.isOpen && r.staffPriority == null,
      );
      expect(report.priority, ReportPriority.defaultFor(report.category));

      await repository.updateStatus(
        report.id,
        status: ReportStatus.underReview,
        note: 'Raised: this is blocking a lecture hall.',
        priority: ReportPriority.urgent,
      );
      final updated = (await repository.watchReports().first).firstWhere(
        (r) => r.id == report.id,
      );
      expect(updated.priority, ReportPriority.urgent);
      expect(
        updated.dueAt,
        updated.createdAt.add(ReportPriority.urgent.target),
      );
    });

    test('overdue means open and past the priority target', () async {
      final reports = await FakeReportRepository().watchReports().first;
      final now = DateTime.now();
      final overdue = overdueReports(reports);

      expect(overdue, isNotEmpty);
      expect(overdue.every((r) => r.status.isOpen), isTrue);
      expect(overdue.every((r) => now.isAfter(r.dueAt)), isTrue);
      expect(
        reports.where(const StaffQueueFilter(overdueOnly: true).matches),
        unorderedEquals(overdue),
      );
    });

    test('status notes must be 10 to 500 characters', () {
      expect(Validators.statusNote('Done'), isNotNull);
      expect(Validators.statusNote('Technician booked for Monday.'), isNull);
      expect(Validators.statusNote('a' * 501), isNotNull);
    });
  });

  group('Dashboard', () {
    Report sample({
      required DateTime created,
      DateTime? resolved,
      ReportCategory category = ReportCategory.water,
      String? team,
    }) {
      return Report(
        id: created.toIso8601String(),
        reference: 'NJ-1',
        title: 'Leaking tap',
        description: 'Water keeps dripping from the tap.',
        category: category,
        building: 'Learning Commons',
        landmark: '',
        status: resolved == null
            ? ReportStatus.submitted
            : ReportStatus.resolved,
        reporterId: 'student-1',
        assignedTeam: team,
        createdAt: created,
        updatedAt: resolved ?? created,
        history: [
          StatusUpdate(
            status: ReportStatus.submitted,
            note: 'Submitted',
            updatedBy: 'Natujali',
            at: created,
          ),
          if (resolved != null)
            StatusUpdate(
              status: ReportStatus.resolved,
              note: 'Fixed',
              updatedBy: 'Plumbing',
              at: resolved,
            ),
        ],
      );
    }

    final now = DateTime(2026, 11, 6, 12);

    test('insights count daily activity and resolution times', () {
      final insights = ReportInsights([
        sample(
          created: DateTime(2026, 11, 4, 9),
          resolved: DateTime(2026, 11, 5, 9),
        ),
        sample(
          created: DateTime(2026, 11, 5, 10),
          resolved: DateTime(2026, 11, 5, 16),
          category: ReportCategory.safety,
        ),
        sample(created: DateTime(2026, 11, 6, 8)),
      ], now: now);

      final week = insights.dailyActivity(7);
      expect(week.length, 7);
      expect(week.last.day, DateTime(2026, 11, 6));
      expect(week.last.opened, 1);
      expect(week[5].opened, 1);
      expect(week[5].resolved, 2);
      expect(insights.averageResolutionTime, const Duration(hours: 15));
      expect(insights.resolvedThisWeek, 2);
      expect(insights.longestOpenWait, const Duration(hours: 4));
      expect(insights.countByCategory.first, (ReportCategory.water, 2));
    });

    test('staff filter combines tab, team and dates', () {
      final reports = [
        sample(created: DateTime(2026, 11, 1), team: 'Plumbing'),
        sample(created: DateTime(2026, 11, 3), team: 'Plumbing'),
        sample(created: DateTime(2026, 11, 3), team: 'Cleaning'),
        sample(
          created: DateTime(2026, 11, 3),
          resolved: DateTime(2026, 11, 4),
          team: 'Plumbing',
        ),
      ];
      final filter = StaffQueueFilter(
        team: 'Plumbing',
        from: DateTime(2026, 11, 2),
        to: DateTime(2026, 11, 3),
      );

      expect(reports.where(filter.matches).length, 1);
    });

    test('sample data has a month of activity to chart', () async {
      final reports = await FakeReportRepository().watchReports().first;
      final month = ReportInsights(reports).dailyActivity(30);
      final activeDays = month.where((day) => day.opened > 0).length;

      expect(activeDays, greaterThan(15));
      expect(
        reports.every((r) => !r.updatedAt.isAfter(DateTime.now())),
        isTrue,
      );
    });
  });
}
