import 'dart:ui';
import 'package:flutter/material.dart';

class CameraFlowBottomBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final VoidCallback? onIdentify;
  final VoidCallback? onDelete;
  final bool isSaveEnabled;
  final bool isIdentifyEnabled;
  final bool isDeleteEnabled;

  const CameraFlowBottomBar({
    super.key,
    this.onBack,
    this.onSave,
    this.onIdentify,
    this.onDelete,
    this.isSaveEnabled = true,
    this.isIdentifyEnabled = true,
    this.isDeleteEnabled = true,
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
                icon: Icons.arrow_back,
                label: 'Tillbaka',
                onTap: onBack,
              ),
              _CameraFlowAction(
                icon: Icons.save_alt_outlined,
                label: 'Spara',
                onTap: isSaveEnabled ? onSave : null,
              ),
              _CameraFlowAction(
                icon: Icons.image_search,
                label: 'Identifiera',
                onTap: isIdentifyEnabled ? onIdentify : null,
                isPrimary: true,
              ),
              _CameraFlowAction(
                icon: Icons.delete_outline,
                label: 'Radera',
                onTap: isDeleteEnabled ? onDelete : null,
                color: const Color(0xFFD03F3F),
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
  final Color? color;

  const _CameraFlowAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final resolvedColor = isEnabled
        ? (color ?? Colors.white)
        : (color ?? Colors.white).withValues(alpha: 0.38);

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
                  color: resolvedColor,
                  size: isPrimary ? 24 : 22,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: resolvedColor,
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