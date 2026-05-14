import 'dart:async';

import 'package:flutter/material.dart';

import '../models/multiplayer_room.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/feature_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/surface_card.dart';

class MultiplayerModeSelectionScreen extends StatelessWidget {
  const MultiplayerModeSelectionScreen({super.key});

  static const routeName = '/multiplayer-mode';

  @override
  Widget build(BuildContext context) {
    unawaited(AppScope.of(context).rememberNavigation(routeName));

    return AppPageShell(
      title: 'MULTIPLAYER MODE',
      centerTitle: true,
      bodyPadding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Text(
                    'SELECT MODE',
                    style: AppTextStyles.subheader.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FeatureTile(
                  icon: Icons.home_outlined,
                  title: 'HOME MODE',
                  description: 'Study with friends on the same device.',
                  onTap: () => _openHomeModeDialog(context),
                ),
                const SizedBox(height: 12),
                FeatureTile(
                  icon: Icons.public_outlined,
                  title: 'AWAY MODE',
                  description: 'Create or join Firebase online study rooms.',
                  onTap: () async {
                    final appState = AppScope.of(context);

                    if (appState.currentUser == null) {
                      final result = await appState.signInAnonymously();

                      if (!context.mounted) {
                        return;
                      }

                      if (!result.success) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(result.message)));
                        return;
                      }
                    }

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pushNamed(
                      '/multiplayer-login',
                      arguments: const MultiplayerLoginArgs(
                        maxPlayers: MultiplayerRoom.minAllowedPlayers,
                        isAwayMode: true,
                        competitiveTimerMode: false,
                        timerMinutes: 30,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Select a multiplayer mode to start your cooperative study session.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openHomeModeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        int selectedMembers = MultiplayerRoom.minAllowedPlayers;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('HOME MODE'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Select how many local members will join, then add exactly that many players.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMembers,
                    decoration: const InputDecoration(labelText: 'MEMBERS'),
                    items:
                        <int>[
                              for (
                                int count = MultiplayerRoom.minAllowedPlayers;
                                count <= MultiplayerRoom.maxAllowedPlayers;
                                count++
                              )
                                count,
                            ]
                            .map(
                              (count) => DropdownMenuItem<int>(
                                value: count,
                                child: Text('$count members'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedMembers = MultiplayerRoom.clampPlayerCount(
                          value,
                        );
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                PrimaryButton(
                  label: 'CONTINUE',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushNamed(
                      '/multiplayer-login',
                      arguments: MultiplayerLoginArgs(
                        maxPlayers: selectedMembers,
                        isAwayMode: false,
                        competitiveTimerMode: false,
                        timerMinutes: 30,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class MultiplayerLoginArgs {
  const MultiplayerLoginArgs({
    required this.maxPlayers,
    required this.isAwayMode,
    required this.competitiveTimerMode,
    required this.timerMinutes,
    this.roomId,
  });

  final int maxPlayers;
  final bool isAwayMode;
  final bool competitiveTimerMode;
  final int timerMinutes;
  final String? roomId;
}

class MultiplayerStudyArgs {
  const MultiplayerStudyArgs({
    required this.users,
    required this.isAwayMode,
    required this.roomId,
    required this.competitiveTimerMode,
    required this.timerMinutes,
    this.localUsername,
    this.restoredFromRefresh = false,
  });

  factory MultiplayerStudyArgs.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'];
    final users = rawUsers is List
        ? rawUsers.map((value) => value.toString()).toList()
        : <String>[];

    return MultiplayerStudyArgs(
      users: users,
      isAwayMode: json['isAwayMode'] as bool? ?? false,
      roomId: (json['roomId'] ?? '').toString(),
      competitiveTimerMode: json['competitiveTimerMode'] as bool? ?? false,
      timerMinutes: (json['timerMinutes'] as num? ?? 30).toInt(),
      localUsername: (json['localUsername'] ?? '').toString().trim().isEmpty
          ? null
          : (json['localUsername'] ?? '').toString(),
      restoredFromRefresh: json['restoredFromRefresh'] as bool? ?? false,
    );
  }

  final List<String> users;
  final bool isAwayMode;
  final String roomId;
  final bool competitiveTimerMode;
  final int timerMinutes;
  final String? localUsername;
  final bool restoredFromRefresh;

  Map<String, dynamic> toJson({bool restoredFromRefresh = false}) {
    return <String, dynamic>{
      'users': users,
      'isAwayMode': isAwayMode,
      'roomId': roomId,
      'competitiveTimerMode': competitiveTimerMode,
      'timerMinutes': timerMinutes,
      'localUsername': localUsername,
      'restoredFromRefresh': restoredFromRefresh,
    };
  }
}
