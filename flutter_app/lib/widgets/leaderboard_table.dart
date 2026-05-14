import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'surface_card.dart';

class LeaderboardTable extends StatelessWidget {
  const LeaderboardTable({
    super.key,
    required this.entries,
    this.tasksLabel = 'TASKS',
  });

  final List<LeaderboardEntry> entries;
  final String tasksLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 560.0;
        final tableWidth = math.max(560.0, availableWidth);
        final listHeight = entries.isEmpty
            ? 72.0
            : math.min(560.0, math.max(55.0, entries.length * 55.0));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _LeaderboardHeader(tasksLabel: tasksLabel),
                  const Divider(height: 1, color: AppColors.primaryLight),
                  SizedBox(
                    height: listHeight,
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              'No leaderboard entries yet.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(
                                      height: 1,
                                      color: AppColors.divider,
                                    ),
                            itemBuilder: (BuildContext context, int index) {
                              return _LeaderboardRow(
                                rank: index + 1,
                                entry: entries[index],
                                isAlt: index.isOdd,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.tasksLabel});

  final String tasksLabel;

  @override
  Widget build(BuildContext context) {
    final TextStyle headerStyle = AppTextStyles.subheader.copyWith(
      color: AppColors.textPrimary,
    );

    Widget cell(String text, int flex) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Text(text, style: headerStyle, textAlign: TextAlign.center),
        ),
      );
    }

    return Container(
      color: AppColors.primary,
      child: Row(
        children: <Widget>[
          cell('RANK', 1),
          cell('STUDENT', 3),
          cell('ROOM XP', 1),
          cell(tasksLabel, 1),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isAlt,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isAlt;

  Color get _rankColor => switch (rank) {
    1 => AppColors.gold,
    2 => AppColors.silver,
    3 => AppColors.bronze,
    _ => AppColors.textPrimary,
  };

  String get _rankBadgeText => switch (rank) {
    1 => 'CHAMPION',
    2 => 'RUNNER UP',
    3 => 'TOP 3',
    _ => '',
  };

  IconData get _rankBadgeIcon => switch (rank) {
    1 => Icons.emoji_events,
    2 => Icons.military_tech,
    3 => Icons.workspace_premium,
    _ => Icons.star,
  };

  Widget _topThreeBadge() {
    if (rank > 3) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _rankColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _rankColor.withValues(alpha: 0.85)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _rankColor.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_rankBadgeIcon, size: 14, color: _rankColor),
          const SizedBox(width: 4),
          Text(
            _rankBadgeText,
            style: AppTextStyles.small.copyWith(
              color: _rankColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cell(String text, int flex, {Color? color, FontWeight? weight}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: weight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      color: isAlt ? AppColors.primaryDark : AppColors.card,
      child: Row(
        children: <Widget>[
          cell(rank.toString(), 1, color: _rankColor, weight: FontWeight.w700),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: <Widget>[
                  _LeaderboardAvatar(entry: entry),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            entry.username,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _topThreeBadge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          cell(entry.xp.toString(), 1),
          cell(entry.completedTasks.toString(), 1),
        ],
      ),
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  const _LeaderboardAvatar({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImage(entry.profileImageBase64);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: bytes == null
            ? const LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.accent],
              )
            : null,
        border: bytes == null
            ? Border.all(color: AppColors.primaryLight)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? Center(
              child: Text(
                _initials(entry.username),
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  _initials(entry.username),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }

  Uint8List? _decodeImage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  String _initials(String username) {
    final parts = username
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
