import 'package:flutter_test/flutter_test.dart';
import 'package:natujali_alu/core/utils/validators.dart';
import 'package:natujali_alu/data/fake_auth_repository.dart';
import 'package:natujali_alu/data/fake_report_repository.dart';
import 'package:natujali_alu/models/report.dart';
import 'package:natujali_alu/models/report_filter.dart';

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
  });

  group('FakeReportRepository', () {
    test('create, update and delete are reflected in the stream', () async {
      final repository = FakeReportRepository();
      const input = ReportInput(
        title: 'Broken door',
        description: 'The library side door does not close properly.',
        category: ReportCategory.facilities,
        building: 'Library',
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
          building: 'Library',
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
}
