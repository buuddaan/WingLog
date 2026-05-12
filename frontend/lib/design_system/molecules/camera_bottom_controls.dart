import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/design_system/atoms/camera_icon_button.dart';
import 'package:frontend/design_system/atoms/camera_shutter_button.dart';
import 'package:frontend/core/theme/app_spacing.dart';

class CameraBottomControls extends StatelessWidget {
  final VoidCallback? onGalleryPressed;
  final VoidCallback? onShutterPressed;
  final VoidCallback? onSwitchCameraPressed;
  final bool isCaptureEnabled;
  final bool isLeftActive;
  final bool isRightActive;
  final IconData leftIcon;
  final IconData rightIcon;
  final EdgeInsetsGeometry? padding;

  const CameraBottomControls({
    super.key,
    required this.onGalleryPressed,
    required this.onShutterPressed,
    required this.onSwitchCameraPressed,
    this.isCaptureEnabled = true,
    this.isLeftActive = true,
    this.isRightActive = true,
    this.leftIcon = Icons.photo_library_outlined,
    this.rightIcon = Icons.cameraswitch_outlined,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CameraIconButton(
            icon: isLeftActive ? Icons.flash_on : Icons.flash_off,
            isActive: isLeftActive,
            onPressed: onGalleryPressed,
            backgroundColor: AppColors.cameraOverlayButton,
            activeBackgroundColor: AppColors.cameraOverlayButton,
            borderColor: Colors.white,
            iconColor: Colors.white,
            activeIconColor: Colors.white,
          ),

          const SizedBox(width: AppSpacing.xl),

          CameraShutterButton(
            onPressed: onShutterPressed,
            isEnabled: isCaptureEnabled,
            outerColor: Colors.transparent,
            innerColor: Colors.white,
            borderColor: Colors.white,
          ),

          const SizedBox(width: AppSpacing.xl),

          CameraIconButton(
            icon: Icons.refresh,
            onPressed: onSwitchCameraPressed,
            backgroundColor: AppColors.cameraOverlayButton,
            activeIconColor: AppColors.cameraOverlayButton,
            borderColor: Colors.white,
            iconColor: Colors.white,
            activeBackgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}