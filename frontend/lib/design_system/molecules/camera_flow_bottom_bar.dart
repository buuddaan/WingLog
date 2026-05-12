import 'dart:ui';
import 'package:flutter/material.dart';

class CameraFlowBottomBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onIdentify;
  final VoidCallback? onSave;
  final bool isIdentifyEnabled;
  final bool isSaveEnabled;

  const CameraFlowBottomBar({
    super.key,
    this.onCancel,
    this.onIdentify,
    this.onSave,
    this.isIdentifyEnabled = true,
    this.isSaveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CameraFlowAction(
                icon: Icons.close,
                label: 'Avbryt',
                onTap: onCancel,
              ),
              _CameraFlowAction(
                icon: Icons.image_search,
                label: 'Identifiera',
                onTap: isIdentifyEnabled ? onIdentify : null,
                isPrimary: true,
              ),
              _CameraFlowAction(
                icon: Icons.check,
                label: 'Spara',
                onTap: isSaveEnabled ? onSave : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraFlowAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _CameraFlowAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isEnabled ? Colors.white : Colors.white38;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isPrimary ? 24 : 22,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}