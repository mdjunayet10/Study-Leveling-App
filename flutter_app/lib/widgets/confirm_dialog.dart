import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String message,
  String title = 'Confirm',
  String confirmLabel = 'YES',
  String cancelLabel = 'CANCEL',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          PrimaryButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            backgroundColor: AppColors.primary,
            hoverColor: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
