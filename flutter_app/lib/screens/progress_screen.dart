import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_formatters.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/placeholder_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_tile.dart';
import '../widgets/surface_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const routeName = '/progress';

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser;
    if (user == null) {
      return PlaceholderScreen(
        title: 'PROGRESS STATISTICS',
        description:
            'Sign in to view dashboard stats, task history, achievements, and analytics.',
        icon: Icons.lock_outline,
        primaryActionLabel: 'LOGIN / SIGN UP',
        onPrimaryAction: () =>
            showSignInRequiredDialog(context, featureName: 'Progress'),
      );
    }

    unawaited(appState.rememberNavigation(routeName));

    return AppPageShell(
      title: 'PROGRESS STATISTICS',
      scrollBody: false,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          '${user.username} | LVL ${user.level}',
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
        ),
      ),
      child: DefaultTabController(
        length: 4,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final isCompact = constraints.maxWidth < 620;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TabBar(
                  isScrollable: isCompact,
                  tabAlignment: isCompact
                      ? TabAlignment.start
                      : TabAlignment.fill,
                  tabs: const <Tab>[
                    Tab(text: 'DASHBOARD'),
                    Tab(text: 'TASK HISTORY'),
                    Tab(text: 'ACHIEVEMENTS'),
                    Tab(text: 'ANALYTICS'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _buildDashboardTab(user),
                      _buildTaskHistoryTab(user),
                      _buildAchievementsTab(context, user, appState),
                      _buildAnalyticsTab(user),
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

  Widget _buildDashboardTab(UserProfile user) {
    final nextLevelXp = user.xpNeededForLevel(user.level);
    final levelProgress = nextLevelXp <= 0
        ? 0.0
        : (user.xp / nextLevelXp).clamp(0.0, 1.0).toDouble();
    final today = DateTime.now();
    final dailyCompleted = user.completedTasksOn(today);
    final weeklyXp = user.xpEarnedThisWeek(today);
    final dailyProgress = (dailyCompleted / user.dailyTaskGoal)
        .clamp(0.0, 1.0)
        .toDouble();
    final weeklyProgress = (weeklyXp / user.weeklyXpGoal)
        .clamp(0.0, 1.0)
        .toDouble();
    final targetLevelProgress = (user.level / user.targetLevel)
        .clamp(0.0, 1.0)
        .toDouble();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final statWidth = constraints.maxWidth < 520
            ? constraints.maxWidth
            : 220.0;

        return ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Text(
              'CURRENT STATS',
              style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                SizedBox(
                  width: statWidth,
                  child: StatTile(
                    label: 'LEVEL',
                    value: user.level.toString(),
                    accentColor: AppColors.level,
                  ),
                ),
                SizedBox(
                  width: statWidth,
                  child: StatTile(
                    label: 'XP',
                    value: user.xp.toString(),
                    accentColor: AppColors.xp,
                  ),
                ),
                SizedBox(
                  width: statWidth,
                  child: StatTile(
                    label: 'COINS',
                    value: user.coins.toString(),
                    accentColor: AppColors.coin,
                  ),
                ),
                SizedBox(
                  width: statWidth,
                  child: StatTile(
                    label: 'TASKS',
                    value: user.totalCompletedTasks.toString(),
                    accentColor: AppColors.success,
                  ),
                ),
                SizedBox(
                  width: statWidth,
                  child: StatTile(
                    label: 'STREAK',
                    value: user.currentStreak.toString(),
                    subtitle: 'Best ${user.longestStreak} days',
                    accentColor: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'LEVEL PROGRESS',
                    style: AppTextStyles.subheader.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: levelProgress),
                  const SizedBox(height: 8),
                  Text(
                    '${user.xp} / $nextLevelXp XP to next level',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'ACTIVE GOALS',
                    style: AppTextStyles.subheader.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildGoalProgress(
                    'Daily tasks',
                    '$dailyCompleted / ${user.dailyTaskGoal}',
                    dailyProgress,
                    AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _buildGoalProgress(
                    'Weekly XP',
                    '$weeklyXp / ${user.weeklyXpGoal}',
                    weeklyProgress,
                    AppColors.xp,
                  ),
                  const SizedBox(height: 12),
                  _buildGoalProgress(
                    'Target level',
                    '${user.level} / ${user.targetLevel}',
                    targetLevelProgress,
                    AppColors.level,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalProgress(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: AppTextStyles.body),
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, minHeight: 10, color: color),
      ],
    );
  }

  Widget _buildTaskHistoryTab(UserProfile user) {
    final completedTasks = user.tasks.where((task) => task.completed).toList();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 760;

        return ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Text(
              'COMPLETE TASK HISTORY',
              style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: 14),
            if (completedTasks.isEmpty)
              SurfaceCard(
                child: Text(
                  'No completed tasks found.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else ...<Widget>[
              if (isWide) _buildTaskHistoryHeader(),
              ...completedTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTaskHistoryItem(task, isWide: isWide),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTaskHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(flex: 3, child: Text('TASK', style: AppTextStyles.small)),
          Expanded(
            child: Text(
              'DIFFICULTY',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            child: Text(
              'XP',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            child: Text(
              'COINS',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            child: Text(
              'STATUS',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            child: Text(
              'DATE',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHistoryItem(StudyTask task, {required bool isWide}) {
    if (!isWide) {
      return SurfaceCard(
        color: AppColors.primaryDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              task.description,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: <Widget>[
                _buildDetailValue('DIFFICULTY', task.difficulty.label),
                _buildDetailValue('XP', task.xpReward.toString()),
                _buildDetailValue('COINS', task.coinReward.toString()),
                _buildDetailValue(
                  'STATUS',
                  'Completed',
                  valueColor: AppColors.success,
                ),
                _buildDetailValue(
                  'DATE',
                  AppFormatters.formatDate(task.completionDate),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SurfaceCard(
      color: AppColors.primaryDark,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              task.description,
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              task.difficulty.label,
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
          Expanded(
            child: Text(
              task.xpReward.toString(),
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          Expanded(
            child: Text(
              task.coinReward.toString(),
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
          Expanded(
            child: Text(
              'Completed',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(color: AppColors.success),
            ),
          ),
          Expanded(
            child: Text(
              AppFormatters.formatDate(task.completionDate),
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailValue(String label, String value, {Color? valueColor}) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.small),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(
    BuildContext context,
    UserProfile user,
    AppState appState,
  ) {
    final completedTasks = user.totalCompletedTasks;
    final achievements = <Map<String, String>>[
      {
        'title': '🔰 Beginner',
        'requirement': 'Complete 1 task',
        'status': completedTasks >= 1 ? 'Unlocked' : 'Locked',
      },
      {
        'title': '🥉 Bronze Scholar',
        'requirement': 'Complete 5 tasks',
        'status': completedTasks >= 5 ? 'Unlocked' : 'Locked',
      },
      {
        'title': '🥈 Silver Scholar',
        'requirement': 'Complete 10 tasks',
        'status': completedTasks >= 10 ? 'Unlocked' : 'Locked',
      },
      {
        'title': '🥇 Gold Scholar',
        'requirement': 'Complete 25 tasks',
        'status': completedTasks >= 25 ? 'Unlocked' : 'Locked',
      },
      {
        'title': '💎 Diamond Scholar',
        'requirement': 'Complete 50 tasks',
        'status': completedTasks >= 50 ? 'Unlocked' : 'Locked',
      },
      {
        'title': '🏆 Study Champion',
        'requirement': 'Complete 100 tasks',
        'status': completedTasks >= 100 ? 'Unlocked' : 'Locked',
      },
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final cardWidth = constraints.maxWidth < 660
            ? constraints.maxWidth
            : 300.0;

        return ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Text(
              'ACHIEVEMENTS',
              style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: achievements.map((achievement) {
                final unlocked = achievement['status'] == 'Unlocked';
                return SizedBox(
                  width: cardWidth,
                  child: SurfaceCard(
                    color: unlocked ? AppColors.primaryDark : AppColors.card,
                    borderColor: unlocked
                        ? AppColors.success
                        : AppColors.primaryLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          achievement['title']!,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement['requirement']!,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          achievement['status']!,
                          style: AppTextStyles.subheader.copyWith(
                            color: unlocked
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _StudyGoalsCard(user: user, appState: appState),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsTab(UserProfile user) {
    final completed = user.tasks.where((task) => task.completed).toList();
    final counts = <TaskDifficulty, int>{
      TaskDifficulty.easy: 0,
      TaskDifficulty.medium: 0,
      TaskDifficulty.hard: 0,
    };

    for (final task in completed) {
      counts[task.difficulty] = (counts[task.difficulty] ?? 0) + 1;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'TASK COMPLETION BY DIFFICULTY',
                style: AppTextStyles.subheader.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              for (final entry in counts.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            entry.key.label,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: completed.isEmpty
                            ? 0.0
                            : entry.value / completed.length,
                        minHeight: 10,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'STUDY CONSISTENCY',
                style: AppTextStyles.subheader.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              _buildDetailValue(
                'CURRENT STREAK',
                '${user.currentStreak} days',
                valueColor: AppColors.warning,
              ),
              const SizedBox(height: 12),
              _buildDetailValue(
                'LONGEST STREAK',
                '${user.longestStreak} days',
                valueColor: AppColors.success,
              ),
              if (user.lastStudyDate != null) ...<Widget>[
                const SizedBox(height: 12),
                _buildDetailValue(
                  'LAST STUDY DAY',
                  AppFormatters.formatDate(user.lastStudyDate),
                  valueColor: AppColors.textPrimary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StudyGoalsCard extends StatefulWidget {
  const _StudyGoalsCard({required this.user, required this.appState});

  final UserProfile user;
  final AppState appState;

  @override
  State<_StudyGoalsCard> createState() => _StudyGoalsCardState();
}

class _StudyGoalsCardState extends State<_StudyGoalsCard> {
  late final TextEditingController _dailyController;
  late final TextEditingController _weeklyController;
  late final TextEditingController _levelController;

  @override
  void initState() {
    super.initState();
    _dailyController = TextEditingController(
      text: widget.user.dailyTaskGoal.toString(),
    );
    _weeklyController = TextEditingController(
      text: widget.user.weeklyXpGoal.toString(),
    );
    _levelController = TextEditingController(
      text: widget.user.targetLevel.toString(),
    );
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'SET STUDY GOALS',
            style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dailyController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Daily Tasks Goal'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weeklyController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Weekly XP Goal'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _levelController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Target Level'),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 160,
              child: PrimaryButton(label: 'SAVE GOALS', onPressed: _saveGoals),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoals() async {
    await widget.appState.updateStudyGoals(
      dailyTasks: int.tryParse(_dailyController.text.trim()) ?? 1,
      weeklyXp: int.tryParse(_weeklyController.text.trim()) ?? 1,
      targetLevel:
          int.tryParse(_levelController.text.trim()) ?? widget.user.targetLevel,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Study goals saved.')));
  }
}
