import 'package:flutter/material.dart';
import 'package:frontend/design_system/atoms/danger_button.dart';
import 'package:frontend/design_system/atoms/neutral_button.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_radius.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirmPressed,
    required this.onCancelPressed,
    this.confirmText = 'Radera',
    this.cancelText = 'Tillbaka',
  });

  final String title;
  final String description;
  final VoidCallback onConfirmPressed;
  final VoidCallback onCancelPressed;
  final String confirmText;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.dialogBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.borderPrimary,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.header4,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: NeutralButton.medium(
                    text: cancelText,
                    onPressed: onCancelPressed,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DangerButton.medium(
                    text: confirmText,
                    onPressed: onConfirmPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}