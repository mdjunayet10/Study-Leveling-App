import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FeatureTile extends StatefulWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.minHeight = 88,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final double minHeight;

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 160),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              constraints: BoxConstraints(minHeight: widget.minHeight),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _hovered
                      ? <Color>[
                          AppColors.primary.withValues(alpha: 0.34),
                          AppColors.cardElevated,
                          AppColors.secondary.withValues(alpha: 0.16),
                        ]
                      : <Color>[
                          AppColors.cardElevated,
                          AppColors.card,
                          AppColors.cardMuted,
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered
                      ? AppColors.accentBright.withValues(alpha: 0.85)
                      : AppColors.border.withValues(alpha: 0.58),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (_hovered
                            ? AppColors.secondary
                            : AppColors.primaryGlow)
                        .withValues(alpha: _hovered ? 0.18 : 0.08),
                    blurRadius: _hovered ? 24 : 14,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentBright.withValues(alpha: 0.45),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.textPrimary,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          widget.title,
                          style: AppTextStyles.subheader.copyWith(
                            color: _hovered
                                ? AppColors.accentBright
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.description,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color:
                        _hovered ? AppColors.accentBright : AppColors.textMuted,
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