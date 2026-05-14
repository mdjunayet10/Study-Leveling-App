import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/primary_button.dart';
import '../widgets/surface_card.dart';
import 'global_leaderboard_screen.dart';
import 'multiplayer_mode_selection_screen.dart';
import 'progress_screen.dart';
import 'reward_screen.dart';
import 'study_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  static const routeName = '/main-menu';

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _appClosed = false;

  Future<void> _openAccountFeature({
    required String featureName,
    required String routeName,
  }) async {
    final appState = AppScope.of(context);

    if (appState.currentUser == null) {
      final result = await appState.signInAnonymously();

      if (!mounted) {
        return;
      }

      if (!result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _exitApp() async {
    if (kIsWeb) {
      setState(() => _appClosed = true);
      return;
    }

    await SystemNavigator.pop();
  }

  void _reopenApp() {
    setState(() => _appClosed = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.hasSignedInAccount ? appState.currentUser : null;

    if (_appClosed) {
      return _ClosedMainMenuView(onReopen: _reopenApp);
    }

    unawaited(appState.rememberNavigation(MainMenuScreen.routeName));

    return AppPageShell(
      title: 'Study Leveling',
      subtitle: user == null
          ? 'Use the app freely. Sign in only when you want a saved account.'
          : 'Stay focused. Complete tasks. Level up.',
      showBackButton: false,
      showAccountButton: true,
      footer: const Align(
        alignment: Alignment.centerRight,
        child: Text('v1.0 • Deep Navy', style: AppTextStyles.small),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (user == null)
                const _GuestSummaryCard()
              else ...<Widget>[
                _StudentSummaryCard(user: user),
                const SizedBox(height: 18),
                _StatsRow(user: user),
              ],
              const SizedBox(height: 18),
              _SimpleMenuPanel(
                isSignedIn: user != null,
                onStudy: () => _openAccountFeature(
                  featureName: 'Start Studying',
                  routeName: StudyScreen.routeName,
                ),
                onRewards: () => _openAccountFeature(
                  featureName: 'Rewards',
                  routeName: RewardScreen.routeName,
                ),
                onProgress: () => _openAccountFeature(
                  featureName: 'Progress',
                  routeName: ProgressScreen.routeName,
                ),
                onMultiplayer: () {
                  Navigator.of(
                    context,
                  ).pushNamed(MultiplayerModeSelectionScreen.routeName);
                },
                onLeaderboard: () {
                  Navigator.of(
                    context,
                  ).pushNamed(GlobalLeaderboardScreen.routeName);
                },
                onExit: _exitApp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosedMainMenuView extends StatelessWidget {
  const _ClosedMainMenuView({required this.onReopen});

  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(24),
                  radius: 18,
                  borderColor: AppColors.accent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentBright),
                        ),
                        child: const Icon(
                          Icons.power_settings_new_rounded,
                          color: AppColors.accentBright,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'App Closed',
                        style: AppTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        kIsWeb
                            ? 'The web version cannot close the browser tab for you. You can close this tab safely.'
                            : 'Study Leveling has been closed.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: 'Open Study Leveling Again',
                        leading: const Icon(Icons.refresh_rounded),
                        onPressed: onReopen,
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final int xpNeeded = user.xpNeededForLevel(user.level);
    final double progress = xpNeeded <= 0
        ? 0
        : (user.xp / xpNeeded).clamp(0.0, 1.0).toDouble();

    final int remainingTasks = user.tasks
        .where((task) => !task.completed)
        .length;

    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(22),
      borderColor: AppColors.primaryLight,
      elevation: 1.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hello, ${user.username}',
            style: AppTextStyles.title.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Text(
            remainingTasks == 0
                ? 'You have no active study tasks yet.'
                : 'You have $remainingTasks active study task${remainingTasks == 1 ? '' : 's'} waiting.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.level.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.level.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  'Level ${user.level}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.level,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${user.xp} / $xpNeeded XP',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.small.copyWith(color: AppColors.xp),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SimpleProgressBar(value: progress),
        ],
      ),
    );
  }
}

class _GuestSummaryCard extends StatelessWidget {
  const _GuestSummaryCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(22),
      borderColor: AppColors.accent,
      elevation: 1.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Welcome, student', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            'Use the app freely without logging in. Sign in only when you want to keep a named account and sync your progress.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _GuestChip(
                icon: Icons.visibility_outlined,
                label: 'Explore freely',
                color: AppColors.info,
              ),
              _GuestChip(
                icon: Icons.cloud_done_outlined,
                label: 'Save with account',
                color: AppColors.success,
              ),
              _GuestChip(
                icon: Icons.public_outlined,
                label: 'Use without login',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestChip extends StatelessWidget {
  const _GuestChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final completedToday = user.completedTasksOn(DateTime.now());

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth < 620;
        final double spacing = 12;
        final double itemWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : (constraints.maxWidth - spacing * 3) / 4;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _SmallStatCard(
                icon: Icons.monetization_on_rounded,
                label: 'Coins',
                value: user.coins.toString(),
                color: AppColors.coin,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SmallStatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '${user.currentStreak} days',
                color: AppColors.warning,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SmallStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Today',
                value: '$completedToday/${user.dailyTaskGoal}',
                color: AppColors.success,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SmallStatCard(
                icon: Icons.flag_rounded,
                label: 'Goal',
                value: 'Lv ${user.targetLevel}',
                color: AppColors.info,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(15),
      borderColor: color.withValues(alpha: 0.45),
      elevation: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.subheader.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _SimpleMenuPanel extends StatelessWidget {
  const _SimpleMenuPanel({
    required this.isSignedIn,
    required this.onStudy,
    required this.onRewards,
    required this.onProgress,
    required this.onMultiplayer,
    required this.onLeaderboard,
    required this.onExit,
  });

  final bool isSignedIn;
  final VoidCallback onStudy;
  final VoidCallback onRewards;
  final VoidCallback onProgress;
  final VoidCallback onMultiplayer;
  final VoidCallback onLeaderboard;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.divider,
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Menu',
            style: AppTextStyles.header.copyWith(color: AppColors.accentBright),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose what you want to do.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _SimpleMenuButton(
            icon: Icons.edit_note_rounded,
            title: 'Start Studying',
            subtitle: isSignedIn
                ? 'Add tasks and use the study timer'
                : 'Use freely without login',
            color: AppColors.primaryLight,
            onTap: onStudy,
          ),
          const SizedBox(height: 12),
          _SimpleMenuButton(
            icon: Icons.card_giftcard_rounded,
            title: 'Rewards',
            subtitle: isSignedIn
                ? 'Use coins for your rewards'
                : 'Use rewards without login',
            color: AppColors.gold,
            onTap: onRewards,
          ),
          const SizedBox(height: 12),
          _SimpleMenuButton(
            icon: Icons.bar_chart_rounded,
            title: 'Progress',
            subtitle: isSignedIn
                ? 'See your levels, streaks, and history'
                : 'View progress without login',
            color: AppColors.success,
            onTap: onProgress,
          ),
          const SizedBox(height: 12),
          _SimpleMenuButton(
            icon: Icons.groups_rounded,
            title: 'Study With Friends',
            subtitle: 'Join or create a study room',
            color: AppColors.info,
            onTap: onMultiplayer,
          ),
          const SizedBox(height: 12),
          _SimpleMenuButton(
            icon: Icons.emoji_events_rounded,
            title: 'Leaderboard',
            subtitle: 'See your rank',
            color: AppColors.warning,
            onTap: onLeaderboard,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Exit App',
              leading: const Icon(Icons.power_settings_new_rounded),
              backgroundColor: AppColors.cardElevated,
              hoverColor: AppColors.error,
              onPressed: onExit,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMenuButton extends StatefulWidget {
  const _SimpleMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_SimpleMenuButton> createState() => _SimpleMenuButtonState();
}

class _SimpleMenuButtonState extends State<_SimpleMenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.01 : 1,
        duration: const Duration(milliseconds: 140),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.13)
                    : AppColors.primaryDark.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered
                      ? widget.color.withValues(alpha: 0.8)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 25),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(widget.title, style: AppTextStyles.subheader),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _hovered ? widget.color : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleProgressBar extends StatelessWidget {
  const _SimpleProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return Container(
      height: 13,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: safeValue,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.primaryLight, AppColors.accentBright],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accentBright.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
