import 'package:flutter/material.dart';
import 'package:frontend/design_system/atoms/camera_icon_button.dart';
import 'package:frontend/design_system/atoms/camera_shutter_button.dart';
import 'package:frontend/core/theme/app_spacing.dart';

class CameraBottomControls extends StatelessWidget {
  final VoidCallback? onGalleryPressed;
  final VoidCallback? onShutterPressed;
  final VoidCallback? onSwitchCameraPressed;
  final bool isCaptureEnabled;
  final IconData leftIcon;
  final IconData rightIcon;
  final EdgeInsetsGeometry? padding;

  const CameraBottomControls({
    super.key,
    required this.onGalleryPressed,
    required this.onShutterPressed,
    required this.onSwitchCameraPressed,
    this.isCaptureEnabled = true,
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
            icon: leftIcon,
            onPressed: onGalleryPressed,
          ),

          const SizedBox(width: AppSpacing.xl),

          CameraShutterButton(
            onPressed: onShutterPressed,
            isEnabled: isCaptureEnabled,
          ),

          const SizedBox(width: AppSpacing.xl),

          CameraIconButton(
            icon: rightIcon,
            onPressed: onSwitchCameraPressed,
          ),
        ],
      ),
    );
  }
}