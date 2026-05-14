import 'package:flutter/material.dart';

import 'screens/global_leaderboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/multiplayer_login_screen.dart';
import 'screens/multiplayer_mode_selection_screen.dart';
import 'screens/multiplayer_study_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/study_screen.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

class StudyLevelingApp extends StatelessWidget {
  const StudyLevelingApp({super.key, this.initialLocation});

  final Map<String, dynamic>? initialLocation;

  @override
  Widget build(BuildContext context) {
    final initialSettings = _initialRouteSettings(AppScope.of(context));

    return MaterialApp(
      title: 'Study Leveling',
      debugShowCheckedModeBanner: false,
      theme: StudyLevelingTheme.dark(),
      initialRoute: initialSettings.name,
      onGenerateInitialRoutes: (_) => <Route<dynamic>>[
        _buildRoute(initialSettings),
      ],
      onGenerateRoute: _buildRoute,
    );
  }

  RouteSettings _initialRouteSettings(AppState appState) {
    final routeName = (initialLocation?['routeName'] ?? '').toString();
    final rawArguments = initialLocation?['arguments'];
    final arguments = rawArguments is Map
        ? Map<String, dynamic>.from(rawArguments)
        : <String, dynamic>{};

    switch (routeName) {
      case StudyScreen.routeName:
      case RewardScreen.routeName:
      case ProgressScreen.routeName:
      case MultiplayerModeSelectionScreen.routeName:
      case GlobalLeaderboardScreen.routeName:
        return RouteSettings(name: routeName);
      case MultiplayerStudyScreen.routeName:
        if (!appState.isAuthenticated) {
          return const RouteSettings(name: MainMenuScreen.routeName);
        }

        final studyArgs = MultiplayerStudyArgs.fromJson(<String, dynamic>{
          ...arguments,
          'restoredFromRefresh': true,
        });
        if (studyArgs.roomId.trim().isEmpty || studyArgs.users.isEmpty) {
          return const RouteSettings(name: MainMenuScreen.routeName);
        }

        return RouteSettings(
          name: MultiplayerStudyScreen.routeName,
          arguments: studyArgs,
        );
      default:
        return const RouteSettings(name: MainMenuScreen.routeName);
    }
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case LoginScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case MainMenuScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MainMenuScreen(),
        );
      case StudyScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const StudyScreen(),
        );
      case RewardScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RewardScreen(),
        );
      case ProgressScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ProgressScreen(),
        );
      case MultiplayerModeSelectionScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MultiplayerModeSelectionScreen(),
        );
      case MultiplayerLoginScreen.routeName:
        final args = settings.arguments as MultiplayerLoginArgs?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MultiplayerLoginScreen(arguments: args),
        );
      case MultiplayerStudyScreen.routeName:
        final args = settings.arguments as MultiplayerStudyArgs?;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MultiplayerStudyScreen(arguments: args),
        );
      case GlobalLeaderboardScreen.routeName:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GlobalLeaderboardScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: MainMenuScreen.routeName),
          builder: (_) => const MainMenuScreen(),
        );
    }
  }
}