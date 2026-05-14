import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/app_state.dart';
import 'services/study_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repository = StudyRepository();
  await repository.initialize();

  final appState = AppState(repository);
  await appState.restorePersistedSession();

  final initialLocation = appState.isAuthenticated
      ? repository.loadLastLocation()
      : null;

  runApp(
    AppScope(
      state: appState,
      child: StudyLevelingApp(initialLocation: initialLocation),
    ),
  );
}
