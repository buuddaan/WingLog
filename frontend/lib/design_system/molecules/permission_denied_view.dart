import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../atoms/primary_gradient_button.dart';
import '../atoms/app_text.dart';
import '../../core/theme/app_spacing.dart';

class PermissionDeniedView extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onRetry;

  const PermissionDeniedView({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white70),
            const SizedBox(height: AppSpacing.lg),
            AppText.title(title, color: Colors.white, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            AppText.body(
              description,
              color: Colors.white70,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryGradientButton.filled(
              text: 'Öppna Inställningar',
              onPressed: () {
                // Detta öppnar automatiskt appens inställningar i telefonen!
                openAppSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}