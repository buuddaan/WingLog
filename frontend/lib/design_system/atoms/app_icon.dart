import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class AppIcon extends StatelessWidget {
  const AppIcon.data(
      this.iconData, {
        super.key,
        this.size = 24,
        this.color = AppColors.textPrimary,
        this.semanticLabel,
      }) : assetPath = null;

  const AppIcon.asset(
      this.assetPath, {
        super.key,
        this.size = 24,
        this.color = AppColors.textPrimary,
        this.semanticLabel,
      }) : iconData = null;

  final IconData? iconData;
  final String? assetPath;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return ImageIcon(
        AssetImage(assetPath!),
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    return Icon(
      iconData,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}