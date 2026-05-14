import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/leaderboard_entry.dart';
import '../models/multiplayer_room.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/countdown_timer_card.dart';
import '../widgets/leaderboard_table.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/surface_card.dart';
import '../widgets/task_tile.dart';
import 'main_menu_screen.dart';
import 'multiplayer_mode_selection_screen.dart';

class MultiplayerStudyScreen extends StatefulWidget {
  const MultiplayerStudyScreen({super.key, this.arguments});

  static const routeName = '/multiplayer-study';
  final MultiplayerStudyArgs? arguments;

  @override
  State<MultiplayerStudyScreen> createState() => _MultiplayerStudyScreenState();
}

class _MultiplayerStudyScreenState extends State<MultiplayerStudyScreen> {
  static const Duration _roomLoadTimeout = Duration(seconds: 12);

  final List<UserProfile> _participants = <UserProfile>[];
  StreamSubscription<MultiplayerRoom?>? _roomSubscription;
  Timer? _taskCountdownTicker;

  bool _loading = true;
  bool _roomMissing = false;
  bool _initialized = false;
  bool _exiting = false;
  bool _exitDialogVisible = false;
  bool _restoreMessageShown = false;
  late String _roomId;
  int _roomMaxPlayers = MultiplayerRoom.minAllowedPlayers;
  String? _localUsername;
  String? _roomErrorMessage;
  final Map<String, int> _roomInitialCompletedTasks = <String, int>{};

  MultiplayerStudyArgs get _args =>
      widget.arguments ??
      const MultiplayerStudyArgs(
        users: <String>['md'],
        isAwayMode: false,
        roomId: 'ROOM01',
        competitiveTimerMode: false,
        timerMinutes: 30,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;
    _roomId = _args.roomId;
    _localUsername =
        _args.localUsername ?? AppScope.of(context).currentUser?.username;
    _startTaskCountdownTicker();
    unawaited(_rememberCurrentRoute());

    if (_args.isAwayMode) {
      _listenToAwayRoom();
    } else {
      _loadParticipants();
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _taskCountdownTicker?.cancel();
    super.dispose();
  }

  void _startTaskCountdownTicker() {
    _taskCountdownTicker?.cancel();
    _taskCountdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _loading || _participants.isEmpty) {
        return;
      }

      final hasTimedRunningTask = _participants.any(
        (participant) => participant.tasks.any(
          (task) =>
              !task.completed && task.timeLimit > 0 && task.startedAt != null,
        ),
      );

      if (hasTimedRunningTask) {
        setState(() {});
      }
    });
  }

  Future<void> _loadParticipants() async {
    final repository = AppScope.of(context).repository;
    final loaded = <UserProfile>[];
    bool restoredFromCachedRoom = false;
    MultiplayerRoom? cachedRoom;

    try {
      cachedRoom = await repository.loadCachedRoom(_roomId);

      if (cachedRoom != null) {
        loaded.addAll(cachedRoom.participants.map((user) => user.copy()));
        restoredFromCachedRoom = true;
      } else {
        for (final username in _args.users) {
          final user =
              await repository.loadUser(username) ??
              UserProfile.newUser(username);
          loaded.add(_roomOnlyParticipant(user));
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _participants.clear();
        _loading = false;
        _roomMissing = true;
        _roomErrorMessage =
            'Could not open the Home room. ${_friendlyRoomError(error)}';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _participants
        ..clear()
        ..addAll(loaded);
      _roomMaxPlayers =
          cachedRoom?.maxPlayers ??
          MultiplayerRoom.clampPlayerCount(_args.users.length);
      _syncRoomBaselines(loaded, room: cachedRoom);
      _loading = false;
      _roomMissing = false;
      _roomErrorMessage = null;
    });

    if (_args.restoredFromRefresh) {
      _showRestoreMessage(
        restoredFromCachedRoom
            ? 'Home room reopened on this device.'
            : 'Home room reopened after reload. Local room tasks could not be fully restored.',
      );
    }
  }

  void _listenToAwayRoom() {
    final appState = AppScope.of(context);
    _roomSubscription?.cancel();
    unawaited(_loadInitialAwayRoom(appState));
    _roomSubscription = appState
        .watchRoom(_roomId)
        .listen(
          (MultiplayerRoom? room) {
            if (!mounted || _exiting) {
              return;
            }

            if (room == null) {
              setState(() {
                _participants.clear();
                _loading = false;
                _roomMissing = true;
                _roomErrorMessage =
                    'The Firebase room $_roomId is no longer available.';
              });
              return;
            }

            _applyRoomSnapshot(room);

            unawaited(_rememberCurrentRoute());
            if (_args.restoredFromRefresh) {
              _showRestoreMessage('Reconnected to room $_roomId.');
            }
          },
          onError: (Object error) {
            if (!mounted || _exiting) {
              return;
            }

            if (_participants.isNotEmpty) {
              setState(() {
                _loading = false;
                _roomErrorMessage =
                    'Live Firebase sync paused. ${_friendlyRoomError(error)}';
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(_roomErrorMessage!)));
              return;
            }

            setState(() {
              _loading = false;
              _roomMissing = true;
              _roomErrorMessage =
                  'Could not sync Firebase room $_roomId. ${_friendlyRoomError(error)}';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not sync room: $error')),
            );
          },
        );
  }

  Future<void> _loadInitialAwayRoom(AppState appState) async {
    try {
      final room = await appState.repository
          .loadRoom(_roomId)
          .timeout(_roomLoadTimeout);

      if (!mounted || _exiting) {
        return;
      }

      if (room == null) {
        setState(() {
          _participants.clear();
          _loading = false;
          _roomMissing = true;
          _roomErrorMessage =
              'Firebase room $_roomId was not found. Check the room code and try again.';
        });
        return;
      }

      _applyRoomSnapshot(room);
      unawaited(_rememberCurrentRoute());
    } catch (error) {
      final cachedRoom = await appState.repository.loadCachedRoom(_roomId);

      if (!mounted || _exiting) {
        return;
      }

      if (cachedRoom != null) {
        _applyRoomSnapshot(cachedRoom);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opened cached room data while Firebase reconnects. ${_friendlyRoomError(error)}',
            ),
          ),
        );
        return;
      }

      setState(() {
        _participants.clear();
        _loading = false;
        _roomMissing = true;
        _roomErrorMessage =
            'Could not open Firebase room $_roomId. ${_friendlyRoomError(error)}';
      });
    }
  }

  void _applyRoomSnapshot(MultiplayerRoom room) {
    if (!mounted || _exiting) {
      return;
    }

    setState(() {
      _participants
        ..clear()
        ..addAll(room.participants.map((user) => user.copy()));
      _roomMaxPlayers = room.maxPlayers;
      _syncRoomBaselines(_participants, room: room);
      _loading = false;
      _roomMissing = false;
      _roomErrorMessage = null;
    });
  }

  Future<void> _syncAndExit() async {
    if (_exiting) {
      return;
    }

    _exiting = true;
    final appState = AppScope.of(context);
    final navigator = Navigator.of(context);
    final localUsername = _localUsername;

    if (_args.isAwayMode) {
      try {
        if (localUsername != null && localUsername.trim().isNotEmpty) {
          await appState
              .leaveRoomAs(_roomId, localUsername)
              .timeout(_roomLoadTimeout);
        }
      } catch (_) {
        // Do not trap the user in the room if Firebase leave cleanup fails.
      }
      await appState.repository.removeCachedRoom(_roomId);
    } else {
      await appState.repository.removeCachedRoom(_roomId);
    }

    await appState.rememberNavigation(MainMenuScreen.routeName);

    await _roomSubscription?.cancel();

    if (!context.mounted) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(MainMenuScreen.routeName, (_) => false);
  }

  Future<void> _requestExitRoom() async {
    if (_exiting || _exitDialogVisible) {
      return;
    }

    _exitDialogVisible = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Exit Room?'),
          content: const Text(
            'Are you sure you want to leave this room? Other players may be affected.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            PrimaryButton(
              label: 'EXIT ROOM',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    _exitDialogVisible = false;

    if (!mounted || shouldExit != true) {
      return;
    }

    await _syncAndExit();
  }

  Future<void> _returnToMultiplayerSelection() async {
    final appState = AppScope.of(context);
    await _roomSubscription?.cancel();
    await appState.repository.removeCachedRoom(_roomId);
    await appState.rememberNavigation(MultiplayerModeSelectionScreen.routeName);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      MultiplayerModeSelectionScreen.routeName,
      (_) => false,
    );
  }

  Future<void> _copyRoomId() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _roomId));
    if (!mounted) {
      return;
    }

    messenger.showSnackBar(const SnackBar(content: Text('Room ID copied.')));
  }

  Future<void> _rememberCurrentRoute() {
    return AppScope.of(context).rememberNavigation(
      MultiplayerStudyScreen.routeName,
      arguments: MultiplayerStudyArgs(
        users: _participants.isEmpty
            ? _args.users
            : _participants.map((player) => player.username).toList(),
        isAwayMode: _args.isAwayMode,
        roomId: _roomId,
        competitiveTimerMode: _args.competitiveTimerMode,
        timerMinutes: _args.timerMinutes,
        localUsername: _localUsername,
      ).toJson(),
    );
  }

  void _showRestoreMessage(String message) {
    if (_restoreMessageShown || !mounted) {
      return;
    }

    _restoreMessageShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  MultiplayerRoom _homeRoomSnapshot() {
    final now = DateTime.now();
    final participants = _participants.map((user) => user.copy()).toList();
    return MultiplayerRoom(
      roomId: _roomId,
      maxPlayers: _roomMaxPlayers,
      creatorUsername: participants.isEmpty
          ? (_localUsername ?? '')
          : participants.first.username,
      createdAt: now,
      competitiveTimer: _args.competitiveTimerMode,
      timerMinutes: _args.timerMinutes,
      participants: participants,
      initialCompletedTasks: Map<String, int>.from(_roomInitialCompletedTasks),
      updatedAt: now,
    );
  }

  Future<void> _cacheHomeRoom() async {
    if (_args.isAwayMode) {
      return;
    }

    await AppScope.of(context).repository.saveCachedRoom(_homeRoomSnapshot());
    await _rememberCurrentRoute();
  }

  UserProfile _roomOnlyParticipant(UserProfile user) {
    final participant = user.copy();
    participant.tasks.clear();
    participant.totalCompletedTasks = 0;
    participant.initialXp = participant.xp;
    participant.initialLevel = participant.level;
    participant.initialCoins = participant.coins;
    participant.trackingInitialized = true;
    return participant;
  }

  List<LeaderboardEntry> _leaderboardEntries() {
    return _participants
        .map(
          (user) => LeaderboardEntry(
            username: user.username,
            level: 1,
            xp: _roomXp(user),
            completedTasks: _roomCompletedTasks(user),
            profileImageBase64: user.profileImageBase64,
          ),
        )
        .toList()
      ..sort((left, right) {
        if (right.xp != left.xp) {
          return right.xp.compareTo(left.xp);
        }

        if (right.completedTasks != left.completedTasks) {
          return right.completedTasks.compareTo(left.completedTasks);
        }

        return left.username.toLowerCase().compareTo(
          right.username.toLowerCase(),
        );
      });
  }

  void _syncRoomBaselines(
    List<UserProfile> participants, {
    MultiplayerRoom? room,
  }) {
    if (room != null) {
      _roomInitialCompletedTasks
        ..clear()
        ..addAll(room.initialCompletedTasks);
    }

    for (final participant in participants) {
      final key = MultiplayerRoom.firebaseUserKey(participant.username);
      _roomInitialCompletedTasks.putIfAbsent(
        key,
        () =>
            room?.initialCompletedTasksFor(participant.username) ??
            participant.totalCompletedTasks,
      );
    }
  }

  int _roomCompletedTasks(UserProfile user) {
    final taskListCompleted = user.tasks.where((task) => task.completed).length;
    if (taskListCompleted > 0) {
      return taskListCompleted;
    }

    final key = MultiplayerRoom.firebaseUserKey(user.username);
    final baseline =
        _roomInitialCompletedTasks[key] ?? user.totalCompletedTasks;
    final completedInRoom = user.totalCompletedTasks - baseline;
    return completedInRoom < 0 ? 0 : completedInRoom;
  }

  int _roomXp(UserProfile user) {
    return user.tasks
        .where((task) => task.completed)
        .fold<int>(0, (total, task) => total + task.xpReward);
  }

  String? _remainingTimeText(StudyTask task) {
    if (task.completed || task.timeLimit <= 0) {
      return null;
    }

    final totalDuration = Duration(minutes: task.timeLimit);
    final startedAt = task.startedAt;
    if (startedAt == null) {
      return '${_formatCompactDuration(totalDuration)} LEFT';
    }

    final remaining = totalDuration - DateTime.now().difference(startedAt);
    if (remaining <= Duration.zero) {
      return 'TIME UP';
    }

    return '${_formatCompactDuration(remaining)} LEFT';
  }

  String _formatCompactDuration(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }

    return '$minutes:${twoDigits(seconds)}';
  }

  bool _canEditParticipant(UserProfile participant) {
    if (!_args.isAwayMode) {
      return true;
    }

    return _isLocalParticipant(participant);
  }

  bool _isLocalParticipant(UserProfile participant, {AppState? appState}) {
    final username = participant.username.trim();
    final localUsername = _localUsername?.trim();
    if (localUsername != null &&
        localUsername.isNotEmpty &&
        localUsername == username) {
      return true;
    }

    if (localUsername != null && localUsername.isNotEmpty) {
      return false;
    }

    final currentUsername = (appState ?? AppScope.of(context))
        .currentUser
        ?.username
        .trim();
    return currentUsername != null &&
        currentUsername.isNotEmpty &&
        currentUsername == username;
  }

  void _showTaskAuthorityMessage(UserProfile participant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Only ${participant.username} can manage those tasks.'),
      ),
    );
  }

  Future<void> _showTaskDialog(
    BuildContext context,
    UserProfile user,
    void Function(StudyTask task) onSave,
  ) async {
    final descriptionController = TextEditingController();
    final timeController = TextEditingController();
    final difficultyNotifier = ValueNotifier<TaskDifficulty>(
      TaskDifficulty.easy,
    );

    final result = await showDialog<StudyTask>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Add Task for ${user.username}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              final difficulty = difficultyNotifier.value;

              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Task description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskDifficulty>(
                      initialValue: difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                      ),
                      items: TaskDifficulty.values
                          .map(
                            (value) => DropdownMenuItem<TaskDifficulty>(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () => difficultyNotifier.value = value,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Time limit (min)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'XP reward: ${difficulty.xpReward}',
                      style: AppTextStyles.small,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coin reward: ${difficulty.coinReward}',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            PrimaryButton(
              label: 'ADD',
              onPressed: () {
                final description = descriptionController.text.trim();
                if (description.isEmpty) {
                  return;
                }

                final difficulty = difficultyNotifier.value;
                final timeLimit = int.tryParse(timeController.text.trim()) ?? 0;
                Navigator.of(dialogContext).pop(
                  StudyTask(
                    description: description,
                    xpReward: difficulty.xpReward,
                    coinReward: difficulty.coinReward,
                    difficulty: difficulty,
                    completed: false,
                    completionDate: null,
                    timeLimit: timeLimit,
                    startedAt: null,
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    difficultyNotifier.dispose();
    descriptionController.dispose();
    timeController.dispose();

    if (result != null) {
      onSave(result);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added "${result.description}".')));
    }
  }

  Future<void> _updateParticipant(
    int index,
    void Function(UserProfile user) mutate,
  ) async {
    if (index < 0 || index >= _participants.length) {
      return;
    }

    final participant = _participants[index];
    if (!_canEditParticipant(participant)) {
      _showTaskAuthorityMessage(participant);
      return;
    }

    mutate(participant);

    final appState = AppScope.of(context);

    try {
      if (_args.isAwayMode) {
        await appState
            .updateRoomParticipant(roomId: _roomId, participant: participant)
            .timeout(_roomLoadTimeout);
        await _rememberCurrentRoute();
      } else {
        await _cacheHomeRoom();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not sync room update. ${_friendlyRoomError(error)}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildParticipantPanel(BuildContext context, int index) {
    final user = _participants[index];
    final canEditParticipant = _canEditParticipant(user);
    final activeTasks = <({int index, StudyTask task})>[
      for (int taskIndex = 0; taskIndex < user.tasks.length; taskIndex++)
        if (!user.tasks[taskIndex].completed)
          (index: taskIndex, task: user.tasks[taskIndex]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '${user.username.toUpperCase()} | LVL ${user.level}',
                style: AppTextStyles.subheader.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: <Widget>[
                  SizedBox(
                    width: 170,
                    child: StatTile(
                      label: 'LEVEL',
                      value: user.level.toString(),
                      accentColor: AppColors.level,
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: StatTile(
                      label: 'XP',
                      value: user.xp.toString(),
                      accentColor: AppColors.xp,
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: StatTile(
                      label: 'COINS',
                      value: user.coins.toString(),
                      accentColor: AppColors.coin,
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: StatTile(
                      label: _args.isAwayMode ? 'ROOM TASKS' : 'HOME TASKS',
                      value: _roomCompletedTasks(user).toString(),
                      accentColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: 'TASKS',
                action: Tooltip(
                  message: canEditParticipant
                      ? 'Add task'
                      : 'Only ${user.username} can add tasks',
                  child: IconButton.filledTonal(
                    onPressed: canEditParticipant
                        ? () => _showTaskDialog(context, user, (task) {
                            setState(() {
                              user.tasks.add(task);
                            });
                            _updateParticipant(index, (_) {});
                          })
                        : null,
                    icon: const Icon(Icons.add),
                    iconSize: 22,
                    visualDensity: VisualDensity.compact,
                    color: canEditParticipant
                        ? AppColors.accentBright
                        : AppColors.textMuted,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${activeTasks.length} ACTIVE MISSION${activeTasks.length == 1 ? '' : 'S'}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: activeTasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks yet.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: activeTasks.length,
                        separatorBuilder: (BuildContext context, int _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int taskIndex) {
                          final activeTask = activeTasks[taskIndex];
                          return TaskTile(
                            task: activeTask.task,
                            onStart:
                                canEditParticipant &&
                                    activeTask.task.startedAt == null
                                ? () => _startParticipantTask(
                                    context,
                                    index,
                                    activeTask.index,
                                  )
                                : null,
                            onComplete: canEditParticipant
                                ? () => _confirmAndCompleteParticipantTask(
                                    context,
                                    index,
                                    activeTask.index,
                                  )
                                : null,
                            onDelete: canEditParticipant
                                ? () => _confirmAndDeleteParticipantTask(
                                    context,
                                    index,
                                    activeTask.index,
                                  )
                                : null,
                            remainingTimeText: _remainingTimeText(
                              activeTask.task,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndCompleteParticipantTask(
    BuildContext context,
    int participantIndex,
    int taskIndex,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message:
          'Complete this task for ${_participants[participantIndex].username}?',
    );
    if (!context.mounted) {
      return;
    }

    if (!confirmed || !mounted) {
      return;
    }

    final user = _participants[participantIndex];
    if (!_canEditParticipant(user)) {
      _showTaskAuthorityMessage(user);
      return;
    }

    final task = user.tasks[taskIndex];
    if (task.completed) {
      return;
    }

    final waitMessage = _completionWaitMessage(task);
    if (waitMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(waitMessage)));
      return;
    }

    final completedAt = DateTime.now();

    setState(() {
      task.completed = true;
      task.completionDate = completedAt;
      user.addXp(task.xpReward);
      user.addCoins(task.coinReward);
      user.incrementCompletedTasksCounter();
      user.registerStudyCompletion(completedAt);
    });

    await AppScope.of(context).applyMultiplayerTaskReward(
      username: user.username,
      task: task,
      completedAt: completedAt,
    );
    await _updateParticipant(participantIndex, (_) {});
  }

  Future<void> _startParticipantTask(
    BuildContext context,
    int participantIndex,
    int taskIndex,
  ) async {
    final user = _participants[participantIndex];
    if (!_canEditParticipant(user)) {
      _showTaskAuthorityMessage(user);
      return;
    }

    setState(() {
      _participants[participantIndex].tasks[taskIndex].startedAt =
          DateTime.now();
    });

    await _updateParticipant(participantIndex, (_) {});
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task started. Keep going before completing it.'),
      ),
    );
  }

  String? _completionWaitMessage(StudyTask task) {
    final startedAt = task.startedAt;
    if (startedAt == null) {
      return 'Start this task first before marking it complete.';
    }

    final minimum = _minimumTaskDuration(task);
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed >= minimum) {
      return null;
    }

    final remainingSeconds = minimum.inSeconds - elapsed.inSeconds;
    final remainingMinutes = (remainingSeconds / 60).ceil();
    final remainingText = remainingMinutes <= 1
        ? 'about 1 minute'
        : 'about $remainingMinutes minutes';
    return 'You need to spend more time on this task before completing it. Try again in $remainingText.';
  }

  Duration _minimumTaskDuration(StudyTask task) {
    if (task.timeLimit <= 0) {
      return const Duration(minutes: 1);
    }

    final requiredSeconds = (task.timeLimit * 60 * 0.2).round();
    return Duration(seconds: requiredSeconds.clamp(60, 600));
  }

  Future<void> _confirmAndDeleteParticipantTask(
    BuildContext context,
    int participantIndex,
    int taskIndex,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Task',
      message:
          'Delete this task for ${_participants[participantIndex].username}?',
      confirmLabel: 'DELETE',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final user = _participants[participantIndex];
    if (!_canEditParticipant(user)) {
      _showTaskAuthorityMessage(user);
      return;
    }

    setState(() {
      _participants[participantIndex].tasks.removeAt(taskIndex);
    });

    await _updateParticipant(participantIndex, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    if (_loading) {
      return AppPageShell(
        title: args.isAwayMode ? 'ONLINE MULTIPLAYER' : 'LOCAL MULTIPLAYER',
        centerTitle: true,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_roomMissing) {
      return AppPageShell(
        title: 'ONLINE MULTIPLAYER',
        centerTitle: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SurfaceCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'ROOM CLOSED OR NOT FOUND',
                    style: AppTextStyles.subheader.copyWith(
                      color: AppColors.warning,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _roomErrorMessage ??
                        'The Firebase room $_roomId is no longer available. The host may have left, or the room code may be incorrect.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'BACK TO MULTIPLAYER',
                    onPressed: _returnToMultiplayerSelection,
                    isExpanded: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_participants.isEmpty) {
      return AppPageShell(
        title: args.isAwayMode ? 'ONLINE MULTIPLAYER' : 'LOCAL MULTIPLAYER',
        centerTitle: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SurfaceCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'NO PLAYERS CONNECTED',
                    style: AppTextStyles.subheader.copyWith(
                      color: AppColors.warning,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _roomErrorMessage ??
                        'Return to multiplayer setup and create or join a room again.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'BACK TO MULTIPLAYER',
                    onPressed: _returnToMultiplayerSelection,
                    isExpanded: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_requestExitRoom());
        }
      },
      child: AppPageShell(
        title: args.isAwayMode ? 'ONLINE MULTIPLAYER' : 'LOCAL MULTIPLAYER',
        subtitle: args.isAwayMode ? 'ROOM: $_roomId' : 'LOCAL STUDY SESSION',
        onBackPressed: _requestExitRoom,
        trailing: args.isAwayMode
            ? PrimaryButton(
                label: 'COPY ROOM ID',
                onPressed: _copyRoomId,
                backgroundColor: AppColors.primaryDark,
                hoverColor: AppColors.primary,
              )
            : null,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 1100;
            final tabs = _participants
                .map((user) => Tab(text: user.username))
                .toList();
            final panels = <Widget>[
              for (int index = 0; index < _participants.length; index++)
                _buildParticipantPanel(context, index),
            ];

            final timerPanel = args.competitiveTimerMode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CountdownTimerCard(
                        minutes: args.timerMinutes,
                        onFinished: () {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Competition timer finished.'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (args.isAwayMode) _buildAwayStatusCard(),
                timerPanel,
                DefaultTabController(
                  length: _participants.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: TabBar(
                          isScrollable: _participants.length > 3,
                          tabs: tabs,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: isWide ? 650 : 920,
                        child: TabBarView(children: panels),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SectionHeader(
                        title: args.isAwayMode
                            ? 'AWAY TASK LEADERBOARD'
                            : 'HOME TASK LEADERBOARD',
                        action: Text(
                          '${_participants.length} CONNECTED',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      LeaderboardTable(
                        entries: _leaderboardEntries(),
                        tasksLabel: 'ROOM TASKS',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAwayStatusCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        color: AppColors.primaryDark,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'LIVE FIREBASE ROOM',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_participants.length} / $_roomMaxPlayers members connected. Share room $_roomId with other devices to join.',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PrimaryButton(label: 'COPY', onPressed: _copyRoomId),
          ],
        ),
      ),
    );
  }

  String _friendlyRoomError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();

    if (error is TimeoutException || lower.contains('timeout')) {
      return 'Firebase did not respond in time.';
    }

    if (lower.contains('permission') || lower.contains('permission_denied')) {
      return 'Firebase Database permission denied. Deploy rules that allow read/write on /multiplayer_rooms/{roomCode}.';
    }

    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network request failed.';
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Please try again.';
    }

    return trimmed.length > 180 ? '${trimmed.substring(0, 180)}...' : trimmed;
  }
}
