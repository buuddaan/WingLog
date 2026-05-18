import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_gradients.dart';
import 'package:frontend/core/theme/app_radius.dart';
import 'package:frontend/core/theme/app_sizes.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

enum PrimaryGradientButtonVariant {
  filled,
  gradient,
}

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton.filled({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
  }) : variant = PrimaryGradientButtonVariant.filled;

  const PrimaryGradientButton.gradient({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
  }) : variant = PrimaryGradientButtonVariant.gradient;

  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final PrimaryGradientButtonVariant variant;

  bool get _isGradient => variant == PrimaryGradientButtonVariant.gradient;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppRadius.md);

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: AppSizes.buttonHeightMd,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: _isGradient ? null : AppColors.softUi,
          gradient: _isGradient ? AppGradients.googleButton : null,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: AppColors.borderPrimary,
            ),
            borderRadius: borderRadius,
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onPressed,
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.buttonPrimary,
                ),
              ),
            ),
          ),
        ),
    );
  }
}