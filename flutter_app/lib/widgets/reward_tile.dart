import 'package:flutter/material.dart';

import '../models/reward_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';
import 'surface_card.dart';

class RewardTile extends StatefulWidget {
  const RewardTile({
    super.key,
    required this.reward,
    required this.onRedeem,
    this.onEdit,
    this.onDelete,
  });

  final RewardItem reward;
  final VoidCallback onRedeem;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<RewardTile> createState() => _RewardTileState();
}

class _RewardTileState extends State<RewardTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: SurfaceCard(
        color: _hovered ? AppColors.primaryLight : AppColors.card,
        borderColor: widget.reward.isCustom
            ? AppColors.accent
            : AppColors.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.reward.name,
              style: AppTextStyles.subheader.copyWith(
                color: AppColors.accentBright,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Center(
                child: Text(
                  _iconForReward(widget.reward.name),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text(
                  '${widget.reward.cost} COINS',
                  style: AppTextStyles.subheader.copyWith(
                    color: AppColors.coin,
                  ),
                ),
              ),
            ),
            if (widget.reward.isCustom) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'CUSTOM',
                style: AppTextStyles.small.copyWith(color: AppColors.accent),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'REDEEM',
              onPressed: widget.onRedeem,
              isExpanded: true,
            ),
            if (widget.reward.isCustom &&
                (widget.onEdit != null || widget.onDelete != null)) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  if (widget.onEdit != null)
                    Expanded(
                      child: PrimaryButton(
                        label: 'EDIT',
                        onPressed: widget.onEdit,
                        backgroundColor: AppColors.primaryDark,
                        hoverColor: AppColors.primary,
                        isExpanded: true,
                      ),
                    ),
                  if (widget.onEdit != null && widget.onDelete != null)
                    const SizedBox(width: 8),
                  if (widget.onDelete != null)
                    Expanded(
                      child: PrimaryButton(
                        label: 'DELETE',
                        onPressed: widget.onDelete,
                        backgroundColor: AppColors.error,
                        hoverColor: AppColors.error,
                        isExpanded: true,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _iconForReward(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('NETFLIX') ||
        upper.contains('TV') ||
        upper.contains('MOVIE')) {
      return '📺';
    }
    if (upper.contains('VIDEO GAMES') || upper.contains('GAME')) return '🎮';
    if (upper.contains('GO OUT') || upper.contains('WALK')) return '🚶';
    if (upper.contains('BREAK') ||
        upper.contains('REST') ||
        upper.contains('COFFEE')) {
      return '☕';
    }
    if (upper.contains('FOOD') ||
        upper.contains('SNACK') ||
        upper.contains('DESSERT')) {
      return '🍔';
    }
    if (upper.contains('MUSIC') || upper.contains('SONG')) return '🎵';
    if (upper.contains('BOOK') || upper.contains('READ')) return '📚';
    if (upper.contains('SOCIAL') || upper.contains('FRIEND')) return '👥';
    if (upper.contains('SHOPPING') || upper.contains('BUY')) return '🛍️';
    if (upper.contains('SLEEP') || upper.contains('NAP')) return '🛌';
    return '🎁';
  }
}
