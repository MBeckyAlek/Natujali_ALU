import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natujali_alu/core/theme/app_theme.dart';
import 'package:natujali_alu/data/announcement_repository.dart';
import 'package:natujali_alu/data/fake_auth_repository.dart';
import 'package:natujali_alu/data/fake_report_repository.dart';
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
      expect(find.textContaining('Similar open'), findsOneWidget);

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
}
