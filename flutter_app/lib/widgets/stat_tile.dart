import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'surface_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      borderColor: accentColor.withValues(alpha: 0.50),
      elevation: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.timer.copyWith(
              color: accentColor,
              shadows: <Shadow>[
                Shadow(
                  color: accentColor.withValues(alpha: 0.45),
                  blurRadius: 18,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: AppTextStyles.small.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}