import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const AppIcon(
      this.icon, {
        super.key,
        this.size,
        this.color,
      });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}