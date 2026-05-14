import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/placeholder_screen.dart';
import '../widgets/pomodoro_timer_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';
import '../widgets/task_tile.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  static const routeName = '/study';

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  static final List<StudyTask> _recommendedTemplates = <StudyTask>[
    StudyTask.fromDifficulty(
      'Read a chapter',
      TaskDifficulty.easy,
      timeLimit: 30,
    ),
    StudyTask.fromDifficulty(
      'Create study notes',
      TaskDifficulty.medium,
      timeLimit: 45,
    ),
    StudyTask.fromDifficulty(
      'Teach a concept to someone',
      TaskDifficulty.hard,
      timeLimit: 60,
    ),
    StudyTask.fromDifficulty(
      'Practice flashcards',
      TaskDifficulty.easy,
      timeLimit: 20,
    ),
    StudyTask.fromDifficulty(
      'Review summary notes',
      TaskDifficulty.medium,
      timeLimit: 35,
    ),
    StudyTask.fromDifficulty(
      'Solve a practice problem set',
      TaskDifficulty.hard,
      timeLimit: 50,
    ),
  ];

  Timer? _countdownTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(AppScope.of(context).rememberNavigation(StudyScreen.routeName));
    _syncCountdownTimer(AppScope.of(context).currentUser);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    final result = await AppScope.of(context).ensureGuestSession();

    if (!mounted || result.success) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser;

    if (user == null) {
      _stopCountdownTimer();
      return PlaceholderScreen(
        title: 'STUDY MISSIONS',
        description:
            'Continue as a guest to create missions, use timers, earn XP, coins, and streak progress.',
        icon: Icons.edit_note_rounded,
        primaryActionLabel: 'CONTINUE AS GUEST',
        onPrimaryAction: _continueAsGuest,
      );
    }

    _syncCountdownTimer(user);

    return AppPageShell(
      title: 'STUDY MISSIONS',
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          '${user.username} | LVL ${user.level}',
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
        ),
      ),
      bodyPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 1100;

          final leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PomodoroTimerCard(),
              const SizedBox(height: 16),
              _buildTasksPanel(context, appState, user),
            ],
          );

          final rightColumn = _buildRecommendedPanel(context, appState, user);

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: leftColumn),
                const SizedBox(width: 16),
                SizedBox(width: 340, child: rightColumn),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              leftColumn,
              const SizedBox(height: 16),
              rightColumn,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTasksPanel(
    BuildContext context,
    AppState appState,
    dynamic user,
  ) {
    final activeTasks = <({int index, StudyTask task})>[
      for (int index = 0; index < user.tasks.length; index++)
        if (!user.tasks[index].completed)
          (index: index, task: user.tasks[index]),
    ];

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(
            title: 'YOUR TASKS',
            action: Tooltip(
              message: 'Add task',
              child: IconButton.filledTonal(
                onPressed: () => _showAddTaskDialog(context, appState),
                icon: const Icon(Icons.add),
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                color: AppColors.accentBright,
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
          const SizedBox(height: 14),
          SizedBox(
            height: 360,
            child: activeTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks yet. Add a mission to begin.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: activeTasks.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final activeTask = activeTasks[index];
                      return TaskTile(
                        task: activeTask.task,
                        onEdit: () => _showTaskDialog(
                          context,
                          appState,
                          index: activeTask.index,
                        ),
                        onStart: activeTask.task.startedAt == null
                            ? () => _startTask(
                                context,
                                appState,
                                activeTask.index,
                              )
                            : null,
                        onComplete: () => _confirmAndCompleteTask(
                          context,
                          appState,
                          activeTask.index,
                        ),
                        onDelete: () => _confirmAndDeleteTask(
                          context,
                          appState,
                          activeTask.index,
                        ),
                        remainingTimeText: _remainingTimeText(activeTask.task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPanel(
    BuildContext context,
    AppState appState,
    dynamic user,
  ) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(
            title: 'RECOMMENDED',
            action: Text(
              '${_recommendedTemplates.length} MISSIONS',
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ..._recommendedTemplates.map((StudyTask template) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                color: AppColors.primaryDark,
                borderColor: AppColors.primaryLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      template.description,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add to your mission list.',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _buildMetaChip(
                          template.difficulty.label,
                          AppColors.accent,
                        ),
                        _buildMetaChip('${template.xpReward} XP', AppColors.xp),
                        _buildMetaChip(
                          '${template.coinReward} COINS',
                          AppColors.coin,
                        ),
                        if (template.timeLimit > 0)
                          _buildMetaChip(
                            '${template.timeLimit} MIN',
                            AppColors.info,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'ADD TO MISSION',
                      onPressed: () async {
                        await appState.addTask(template.copy());
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${template.description}".'),
                          ),
                        );
                      },
                      textStyle: AppTextStyles.small.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _confirmAndCompleteTask(
    BuildContext context,
    AppState appState,
    int index,
  ) async {
    final task = appState.currentUser?.tasks.elementAtOrNull(index);
    if (task == null) {
      return;
    }

    final waitMessage = _completionWaitMessage(task);
    if (waitMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(waitMessage)));
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      message: 'Are you sure you want to complete this task?',
    );

    if (!confirmed) {
      return;
    }

    try {
      final previousLevel = appState.currentUser?.level ?? 0;
      await appState.completeTaskAt(index);
      _syncCountdownTimer(appState.currentUser);
      if (!context.mounted) {
        return;
      }
      final currentLevel = appState.currentUser?.level ?? previousLevel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLevel > previousLevel
                ? 'Level up! You reached level $currentLevel.'
                : 'Task completed. Streak updated.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not complete task.')));
    }
  }

  Future<void> _startTask(
    BuildContext context,
    AppState appState,
    int index,
  ) async {
    await appState.startTaskAt(index);
    _ensureCountdownTimer();
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

    return Duration(minutes: task.timeLimit);
  }

  String? _remainingTimeText(StudyTask task) {
    final startedAt = task.startedAt;
    if (startedAt == null || task.completed) {
      return null;
    }

    final remaining = _remainingTime(task);
    if (remaining <= Duration.zero) {
      return 'Time remaining: 00:00';
    }

    return 'Time remaining: ${_formatRemainingTime(remaining)}';
  }

  Duration _remainingTime(StudyTask task) {
    final startedAt = task.startedAt;
    if (startedAt == null) {
      return Duration.zero;
    }

    return _minimumTaskDuration(task) - DateTime.now().difference(startedAt);
  }

  String _formatRemainingTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _syncCountdownTimer(dynamic user) {
    final hasRunningCountdown =
        user?.tasks.any(
          (task) =>
              !task.completed &&
              task.startedAt != null &&
              _remainingTime(task) > Duration.zero,
        ) ??
        false;

    if (hasRunningCountdown) {
      _ensureCountdownTimer();
    } else {
      _stopCountdownTimer();
    }
  }

  void _ensureCountdownTimer() {
    if (_countdownTimer?.isActive ?? false) {
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _confirmAndDeleteTask(
    BuildContext context,
    AppState appState,
    int index,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      message: 'Are you sure you want to delete this task?',
    );

    if (!confirmed) {
      return;
    }

    try {
      await appState.removeTaskAt(index);
      _syncCountdownTimer(appState.currentUser);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete task.')));
    }
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    AppState appState,
  ) async {
    await _showTaskDialog(context, appState);
  }

  Future<void> _showTaskDialog(
    BuildContext context,
    AppState appState, {
    int? index,
  }) async {
    final existingTask = index == null
        ? null
        : appState.currentUser?.tasks.elementAtOrNull(index);
    final descriptionController = TextEditingController(
      text: existingTask?.description ?? '',
    );
    final timeController = TextEditingController(
      text: existingTask?.timeLimit == null || existingTask!.timeLimit <= 0
          ? ''
          : existingTask.timeLimit.toString(),
    );
    final difficultyNotifier = ValueNotifier<TaskDifficulty>(
      existingTask?.difficulty ?? TaskDifficulty.easy,
    );

    final task = await showDialog<StudyTask>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(existingTask == null ? 'Add New Task' : 'Edit Task'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              final selectedDifficulty = difficultyNotifier.value;

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
                      initialValue: selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                      ),
                      items: TaskDifficulty.values
                          .map(
                            (difficulty) => DropdownMenuItem<TaskDifficulty>(
                              value: difficulty,
                              child: Text(difficulty.label),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: timeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Time limit (min)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                              text: selectedDifficulty.xpReward.toString(),
                            ),
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'XP reward',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Coin reward: ${selectedDifficulty.coinReward}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
              label: existingTask == null ? 'ADD' : 'SAVE',
              onPressed: () {
                final description = descriptionController.text.trim();
                if (description.isEmpty) {
                  return;
                }

                final timeLimit = int.tryParse(timeController.text.trim()) ?? 0;
                final difficulty = difficultyNotifier.value;
                Navigator.of(dialogContext).pop(
                  StudyTask(
                    description: description,
                    xpReward: difficulty.xpReward,
                    coinReward: difficulty.coinReward,
                    difficulty: difficulty,
                    completed: existingTask?.completed ?? false,
                    completionDate: existingTask?.completionDate,
                    timeLimit: timeLimit,
                    startedAt: existingTask?.startedAt,
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

    if (task != null) {
      if (index == null) {
        await appState.addTask(task);
      } else {
        await appState.updateTaskAt(index, task);
      }
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(index == null ? 'Task added.' : 'Task saved.')),
      );
    }
  }
}
