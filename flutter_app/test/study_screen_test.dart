import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_leveling_flutter/app.dart';
import 'package:study_leveling_flutter/services/app_state.dart';
import 'package:study_leveling_flutter/services/study_repository.dart';

void main() {
  testWidgets('task stack uses inline icon actions with confirmation dialogs', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(1200, 850));

    final appState = await _createAppState();
    await appState.signUp(
      'stack_user',
      '1234',
      email: 'stack_user@study.local',
    );
    await appState.signIn('stack_user', '1234');

    await tester.pumpWidget(
      AppScope(state: appState, child: const StudyLevelingApp()),
    );

    await tester.tap(find.text('Start Studying'));
    await tester.pumpAndSettle();

    expect(find.text('STUDY MISSIONS'), findsOneWidget);
    expect(find.byTooltip('Add task'), findsOneWidget);
    expect(find.text('COMPLETE TASK'), findsNothing);
    expect(find.text('DELETE TASK'), findsNothing);

    await tester.tap(find.text('ADD TO MISSION').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Start task'), findsOneWidget);
    expect(find.byTooltip('Complete task'), findsOneWidget);
    expect(find.byTooltip('Delete task'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.text('Are you sure you want to complete this task?'),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.play_circle_outline_rounded));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('Time remaining:'), findsOneWidget);

    appState.currentUser!.tasks.first.startedAt = DateTime.now().subtract(
      const Duration(minutes: 31),
    );
    await appState.repository.saveUser(appState.currentUser!);

    expect(
      find.text('Are you sure you want to complete this task?'),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.text('Are you sure you want to complete this task?'),
      findsOneWidget,
    );

    await tester.tap(find.text('YES'));
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet. Add a mission to begin.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
