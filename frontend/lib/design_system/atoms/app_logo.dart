import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_images.dart';

class AppLogo extends StatelessWidget {
  final double? width;

  const AppLogo({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppImages.logo,
      width: 280,
    );
  }
}