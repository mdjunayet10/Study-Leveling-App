import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_leveling_flutter/app.dart';
import 'package:study_leveling_flutter/screens/progress_screen.dart';
import 'package:study_leveling_flutter/services/app_state.dart';
import 'package:study_leveling_flutter/services/study_repository.dart';
import 'package:study_leveling_flutter/theme/app_theme.dart';

void main() {
  testWidgets('opens the Progress screen from the main menu on desktop', (
    tester,
  ) async {
    await _verifyProgressNavigation(tester, const Size(1200, 800));
  });

  testWidgets('opens the Progress screen from the main menu on mobile', (
    tester,
  ) async {
    await _verifyProgressNavigation(tester, const Size(390, 844));
  });

  testWidgets(
    'shows a login prompt instead of a blank Progress screen without a user',
    (tester) async {
      _setSurfaceSize(tester, const Size(390, 844));

      final appState = await _createAppState();
      await tester.pumpWidget(
        AppScope(
          state: appState,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: StudyLevelingTheme.dark(),
            home: const ProgressScreen(),
          ),
        ),
      );

      expect(find.text('PROGRESS STATISTICS'), findsWidgets);
      expect(
        find.text(
          'Sign in to view dashboard stats, task history, achievements, and analytics.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _verifyProgressNavigation(WidgetTester tester, Size size) async {
  _setSurfaceSize(tester, size);

  final appState = await _createAppState();
  await appState.signIn('md', '1234');
  await tester.pumpWidget(
    AppScope(state: appState, child: const StudyLevelingApp()),
  );

  expect(find.text('Menu'), findsOneWidget);

  await tester.ensureVisible(find.text('Progress'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Progress'));
  await tester.pumpAndSettle();

  expect(find.text('PROGRESS STATISTICS'), findsOneWidget);
  expect(find.text('CURRENT STATS'), findsOneWidget);
  expect(find.text('DASHBOARD'), findsOneWidget);
  expect(find.text('TASK HISTORY'), findsOneWidget);
  expect(find.text('ACHIEVEMENTS'), findsOneWidget);
  expect(find.text('ANALYTICS'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<AppState> _createAppState() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final repository = StudyRepository();
  await repository.initialize();
  return AppState(repository);
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
