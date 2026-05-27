import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/design_system/atoms/camera_icon_button.dart';
import 'package:frontend/design_system/atoms/camera_shutter_button.dart';

class CameraBottomControls extends StatelessWidget {
  final VoidCallback? onCancelSessionPressed;
  final VoidCallback? onShutterPressed;
  final VoidCallback? onSaveSessionPressed;
  final VoidCallback? onSwitchCameraPressed;
  final bool isCaptureEnabled;
  final bool isSessionActionEnabled;
  final EdgeInsetsGeometry? padding;

  const CameraBottomControls({
    super.key,
    required this.onCancelSessionPressed,
    required this.onShutterPressed,
    required this.onSaveSessionPressed,
    required this.onSwitchCameraPressed,
    this.isCaptureEnabled = true,
    this.isSessionActionEnabled = true,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: CameraIconButton(
                icon: Icons.close,
                  onPressed:
                    isSessionActionEnabled ? onCancelSessionPressed : null,
                backgroundColor: AppColors.cameraOverlayButton,
                activeBackgroundColor: AppColors.cameraOverlayButton,
                borderColor: Colors.white,
                iconColor: Colors.white,
                activeIconColor: Colors.white,
              ),
            ),
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

          Expanded(
              child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CameraIconButton(
              icon: Icons.cameraswitch_outlined,
              onPressed: onSwitchCameraPressed,
              backgroundColor: AppColors.cameraOverlayButton,
              activeBackgroundColor: AppColors.cameraOverlayButton,
              borderColor: Colors.white,
              iconColor: Colors.white,
              activeIconColor: Colors.white,
            ),
            const SizedBox(width: AppSpacing.md),
            CameraIconButton(
              icon: Icons.save_alt_outlined,
              onPressed:
              isSessionActionEnabled ? onSaveSessionPressed : null,
              backgroundColor: AppColors.cameraOverlayButton,
              activeBackgroundColor: AppColors.cameraOverlayButton,
              borderColor: Colors.white,
              iconColor: Colors.white,
              activeIconColor: Colors.white,
          ),
         ],
        ),
       ),
     ],
    ),
    );
  }
}