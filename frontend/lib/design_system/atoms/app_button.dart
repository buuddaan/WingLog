import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_radius.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_gradients.dart';

enum AppButtonVariant {
  primaryLogin,
  googleLogin,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final AppButtonVariant variant;

  const AppButton.primaryLogin({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
  }) : variant = AppButtonVariant.primaryLogin;

  const AppButton.googleLogin({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
  }) : variant = AppButtonVariant.googleLogin;

  @override
  Widget build(BuildContext context) {
    final isGoogle = variant ==AppButtonVariant.googleLogin;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: Container(
        height: 55,
        decoration: ShapeDecoration(
          color: isGoogle ? null : AppColors.softUi,
          gradient: isGoogle ? AppGradients.googleButton : null,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: AppColors.borderPrimary,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onPressed,
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
