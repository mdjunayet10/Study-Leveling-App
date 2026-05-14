import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_page_shell.dart';
import 'primary_button.dart';
import 'surface_card.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.centerTitle = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return AppPageShell(
      title: title,
      centerTitle: centerTitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: AppColors.accentBright, size: 56),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.header,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onPrimaryAction != null &&
                    primaryActionLabel != null) ...<Widget>[
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: primaryActionLabel!,
                    onPressed: onPrimaryAction,
                    isExpanded: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
