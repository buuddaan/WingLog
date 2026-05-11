import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/design_system/atoms/app_icon.dart';
import 'package:frontend/core/theme/app_sizes.dart';

class CameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final double? size;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? activeBackgroundColor;
  final Color? iconColor;
  final Color? activeIconColor;
  final Color? borderColor;

  const CameraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.size,
    this.iconSize,
    this.backgroundColor,
    this.activeBackgroundColor,
    this.iconColor,
    this.activeIconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? AppSizes.cameraControlButtonSize;
    final currentIconSize = iconSize ?? AppSizes.cameraControlIconSize;

    final currentBackgroundColor = isActive
        ? (activeBackgroundColor ?? AppColors.softUi)
        : (backgroundColor ?? AppColors.shadow);

    final currentIconColor = isActive
        ? (activeIconColor ?? AppColors.textPrimary)
        : (iconColor ?? AppColors.textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentBackgroundColor,
            border: Border.all(
              color: borderColor ?? AppColors.borderPrimary,
              width: 1,
            ),
          ),
          child: Center(
            child: AppIcon(
              icon,
              size: currentIconSize,
              color: currentIconColor,
            ),
          ),
        ),
      ),
    );
  }
}