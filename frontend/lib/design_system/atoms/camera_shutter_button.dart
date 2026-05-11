import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_sizes.dart';

class CameraShutterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color? outerColor;
  final Color? innerColor;
  final Color? borderColor;

  const CameraShutterButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
    this.outerColor,
    this.innerColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final currentOuterColor = outerColor ?? AppColors.softUi;
    final currentInnerColor = innerColor ?? AppColors.textPrimary;
    final currentBorderColor = borderColor ?? AppColors.borderPrimary;

    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: Ink(
            width: AppSizes.cameraShutterOuterSize,
            height: AppSizes.cameraShutterOuterSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentOuterColor,
              border: Border.all(
                color: currentBorderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Container(
                width: AppSizes.cameraShutterInnerSize,
                height: AppSizes.cameraShutterInnerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentInnerColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}