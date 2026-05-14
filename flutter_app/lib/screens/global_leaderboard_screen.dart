import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_page_shell.dart';

class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  static const routeName = '/global-leaderboard';

  @override
  State<GlobalLeaderboardScreen> createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen> {
  Future<_LeaderboardLoadResult>? _entriesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(
      AppScope.of(
        context,
      ).rememberNavigation(GlobalLeaderboardScreen.routeName),
    );
    _entriesFuture ??= _loadLeaderboard();
  }

  Future<_LeaderboardLoadResult> _loadLeaderboard() async {
    final appState = AppScope.of(context);
    final currentUser = appState.hasSignedInAccount
        ? appState.currentUser
        : null;

    if (currentUser != null) {
      try {
        await appState.repository.submitLeaderboardEntry(currentUser);
      } catch (_) {
        // Loading the leaderboard should still work if the current sync fails.
      }
    }

    final entries = await appState.repository.loadLeaderboardEntries();

    return _LeaderboardLoadResult(entries: entries, currentUser: currentUser);
  }

  Uint8List? _decodeProfileImage(String? value) {
    if (value == null || value.trim().isEmpty) {
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

  Color _rankColor(int rank) {
    if (rank == 1) {
      return AppColors.gold;
    }

    if (rank == 2) {
      return AppColors.silver;
    }

    if (rank == 3) {
      return AppColors.bronze;
    }

    return AppColors.textPrimary;
  }

  String _rankBadgeText(int rank) {
    if (rank == 1) {
      return 'CHAMPION';
    }

    if (rank == 2) {
      return 'RUNNER UP';
    }

    if (rank == 3) {
      return 'TOP 3';
    }

    return '';
  }

  IconData _rankBadgeIcon(int rank) {
    if (rank == 1) {
      return Icons.emoji_events;
    }

    if (rank == 2) {
      return Icons.military_tech;
    }

    return Icons.workspace_premium;
  }

  Widget _topThreeBadge(int rank) {
    if (rank > 3) {
      return const SizedBox.shrink();
    }

    final badgeColor = _rankColor(rank);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: badgeColor.withValues(alpha: 0.85)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_rankBadgeIcon(rank), size: 15, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            _rankBadgeText(rank),
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar({required String username, required String? imageBase64}) {
    final imageBytes = _decodeProfileImage(imageBase64);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageBytes == null
            ? const LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.accent],
              )
            : null,
        border: imageBytes == null
            ? Border.all(color: AppColors.accentBright.withValues(alpha: 0.55))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes == null
          ? Center(
              child: Text(
                _initials(username),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  _initials(username),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _rankingCard(
    LeaderboardEntry entry,
    int index, {
    required bool isCurrentUser,
  }) {
    final rank = index + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.accent.withValues(alpha: 0.13)
            : AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.accentBright
              : rank <= 3
              ? _rankColor(rank)
              : AppColors.border,
          width: isCurrentUser || rank <= 3 ? 1.8 : 1.1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 54,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: isCurrentUser
                    ? AppColors.accentBright
                    : _rankColor(rank),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 14),
          _avatar(
            username: entry.username,
            imageBase64: entry.profileImageBase64,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        entry.username,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentBright.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.accentBright),
                        ),
                        child: Text(
                          'YOU',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.accentBright,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      _topThreeBadge(rank),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Level ${entry.level}  •  ${entry.xp} XP  •  ${entry.completedTasks} tasks',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageShell(
      title: 'GLOBAL RANKINGS',
      centerTitle: true,
      child: FutureBuilder<_LeaderboardLoadResult>(
        future: _entriesFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<_LeaderboardLoadResult> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    'Failed to load global leaderboard data.\n\n${snapshot.error}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final result =
                  snapshot.data ??
                  const _LeaderboardLoadResult(entries: <LeaderboardEntry>[]);

              final entries = result.entries;
              final currentUsername = result.currentUser?.username
                  .trim()
                  .toLowerCase();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'LIVE GLOBAL RANKINGS',
                    style: AppTextStyles.subheader.copyWith(
                      color: AppColors.accentBright,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GLOBAL RANKING LIST',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (entries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'No leaderboard entries were found.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    SizedBox(
                      height: 430,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: entries.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 0),
                        itemBuilder: (BuildContext context, int index) {
                          final entry = entries[index];
                          final isCurrentUser =
                              currentUsername != null &&
                              entry.username.trim().toLowerCase() ==
                                  currentUsername;

                          return _rankingCard(
                            entry,
                            index,
                            isCurrentUser: isCurrentUser,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }
}

class _LeaderboardLoadResult {
  const _LeaderboardLoadResult({required this.entries, this.currentUser});

  final List<LeaderboardEntry> entries;
  final UserProfile? currentUser;
}
