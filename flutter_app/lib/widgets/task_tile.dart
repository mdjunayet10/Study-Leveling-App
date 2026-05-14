import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'surface_card.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.selected = false,
    this.onTap,
    this.onEdit,
    this.onStart,
    this.onComplete,
    this.onDelete,
    this.remainingTimeText,
  });

  final StudyTask task;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final String? remainingTimeText;

  Color get _difficultyColor => switch (task.difficulty) {
    TaskDifficulty.easy => AppColors.easy,
    TaskDifficulty.medium => AppColors.medium,
    TaskDifficulty.hard => AppColors.hard,
  };

  String get _difficultyIcon => switch (task.difficulty) {
    TaskDifficulty.easy => '🟢',
    TaskDifficulty.medium => '🟡',
    TaskDifficulty.hard => '🔴',
  };

  @override
  Widget build(BuildContext context) {
    final actionButtons = <Widget>[
      if (onEdit != null)
        Tooltip(
          message: 'Edit task',
          child: IconButton(
            onPressed: onEdit,
            iconSize: 24,
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.accent,
          ),
        ),
      if (onStart != null)
        Tooltip(
          message: 'Start task',
          child: IconButton(
            onPressed: onStart,
            iconSize: 24,
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            icon: const Icon(Icons.play_circle_outline_rounded),
            color: AppColors.info,
          ),
        ),
      if (onComplete != null)
        Tooltip(
          message: 'Complete task',
          child: IconButton(
            onPressed: onComplete,
            iconSize: 24,
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            icon: const Icon(Icons.check_circle_outline),
            color: AppColors.success,
          ),
        ),
      if (onDelete != null)
        Tooltip(
          message: 'Delete task',
          child: IconButton(
            onPressed: onDelete,
            iconSize: 24,
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 520;
        final statusIcon = Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: task.completed
                ? AppColors.success.withValues(alpha: 0.16)
                : AppColors.primaryDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: task.completed
                  ? AppColors.success
                  : AppColors.primaryLight,
            ),
          ),
          child: Center(
            child: Text(
              task.completed ? '✓' : '○',
              style: AppTextStyles.subheader.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              task.description,
              style: AppTextStyles.body.copyWith(
                color: task.completed
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: task.completed ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _Chip(label: _difficultyIcon, color: _difficultyColor),
                _Chip(label: task.difficulty.label, color: _difficultyColor),
                _Chip(label: '${task.xpReward} XP', color: AppColors.xp),
                _Chip(label: '${task.coinReward} COINS', color: AppColors.coin),
                if (task.timeLimit > 0)
                  _Chip(
                    label: '${task.timeLimit} MIN',
                    color: AppColors.accent,
                  ),
                if (!task.completed && task.startedAt != null)
                  _Chip(label: 'STARTED', color: AppColors.info),
                if (remainingTimeText != null)
                  _Chip(label: remainingTimeText!, color: AppColors.warning),
              ],
            ),
          ],
        );

        final actions = actionButtons.isEmpty
            ? null
            : Wrap(
                spacing: 2,
                runSpacing: 2,
                alignment: compact ? WrapAlignment.end : WrapAlignment.center,
                children: actionButtons,
              );

        return InkWell(
          onTap: onTap,
          child: SurfaceCard(
            color: selected ? AppColors.primaryLight : AppColors.card,
            borderColor: selected
                ? AppColors.accentBright
                : AppColors.primaryLight,
            borderWidth: selected ? 2 : 1,
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          statusIcon,
                          const SizedBox(width: 12),
                          Expanded(child: content),
                        ],
                      ),
                      if (actions != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      statusIcon,
                      const SizedBox(width: 14),
                      Expanded(child: content),
                      if (actions != null) ...<Widget>[
                        const SizedBox(width: 8),
                        actions,
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
}
