import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natujali_alu/core/theme/app_theme.dart';
import 'package:natujali_alu/data/announcement_repository.dart';
import 'package:natujali_alu/data/fake_auth_repository.dart';
import 'package:natujali_alu/data/fake_report_repository.dart';
import 'package:natujali_alu/models/report.dart';
import 'package:natujali_alu/providers/announcement_providers.dart';
import 'package:natujali_alu/providers/auth_providers.dart';
import 'package:natujali_alu/providers/report_providers.dart';
import 'package:natujali_alu/screens/report_form/report_form_screen.dart';

void main() {
  testWidgets(
    'report form scrolls to Submit with large text, dark mode and the '
    'keyboard open',
    (tester) async {
      // A typical Android phone: 1080 × 2400 at 2.625×.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      final announcements = FakeAnnouncementRepository();
      await announcements.post(
        title: 'Water off on the 2nd floor',
        message: 'Plumbing work until 4 pm.',
        building: 'Social Commons',
        postedBy: 'Joseph Mensah',
        duration: const Duration(hours: 2),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              FakeAuthRepository.demoStudent,
            ),
            reportRepositoryProvider.overrideWithValue(FakeReportRepository()),
            announcementRepositoryProvider.overrideWithValue(announcements),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const ReportFormScreen(),
          ),
        ),
      );
      await tester.pump();
      final form = find.byType(Scrollable).first;

      // Water + Social Commons shows both the duplicate warning and the
      // building's announcement, the longest version of the form.
      await tester.tap(find.text('Water'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Choose a building'),
        200,
        scrollable: form,
      );
      await tester.tap(find.text('Choose a building'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Social Commons').last);
      await tester.pumpAndSettle();
      expect(find.text('Staff already know about:'), findsOneWidget);
      // The demo student filed the open water report there themselves.
      expect(find.text('You already reported this'), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pumpAndSettle();

      for (final label in ['Choose photo', 'Submit report']) {
        await tester.scrollUntilVisible(
          find.text(label),
          300,
          scrollable: form,
        );
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('similar report by another student offers "Me too" in the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final reports = FakeReportRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(FakeAuthRepository.demoStudent),
          reportRepositoryProvider.overrideWithValue(reports),
          announcementRepositoryProvider.overrideWithValue(
            FakeAnnouncementRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => ReportFormScreen.open(context),
                  child: const Text('Report'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    final form = find.byType(Scrollable).first;

    // Another student's handrail report is open in Enterprise Commons.
    await tester.tap(find.text('Safety'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Choose a building'),
      200,
      scrollable: form,
    );
    await tester.tap(find.text('Choose a building'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enterprise Commons').last);
    await tester.pumpAndSettle();
    expect(find.text('Someone already reported this'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Me too'), 200, scrollable: form);
    await tester.tap(find.text('Me too'));
    await tester.pumpAndSettle();

    // The form closes and the student now backs an existing report.
    expect(find.byType(ReportFormScreen), findsNothing);
    final backed = (await reports.watchReports().first).where(
      (r) =>
          r.category == ReportCategory.safety &&
          r.isSupportedBy(FakeAuthRepository.demoStudent.uid),
    );
    expect(backed, isNotEmpty);
  });
}
