import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.centerTitle = false,
  });

  final String title;
  final Widget? action;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final List<Widget> actionWidgets =
        action == null ? const <Widget>[] : <Widget>[action!];

    final titleWidget = Text(
      title,
      style: AppTextStyles.subheader.copyWith(
        color: AppColors.accentBright,
        shadows: <Shadow>[
          Shadow(
            color: AppColors.secondary.withValues(alpha: 0.45),
            blurRadius: 14,
          ),
        ],
      ),
      textAlign: centerTitle ? TextAlign.center : TextAlign.left,
    );

    if (centerTitle) {
      return Column(
        children: <Widget>[
          Center(child: titleWidget),
          const SizedBox(height: 8),
          _DividerGlow(),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: titleWidget),
              ...actionWidgets,
            ],
          ),
          const SizedBox(height: 10),
          _DividerGlow(),
        ],
      ),
    );
  }
}

class _DividerGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary.withValues(alpha: 0.0),
            AppColors.primaryLight.withValues(alpha: 0.75),
            AppColors.secondary.withValues(alpha: 0.55),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}