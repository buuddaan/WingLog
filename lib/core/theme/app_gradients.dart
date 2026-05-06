import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment(0.5, -0.00),
    end: Alignment(0.5, 1),
    colors: [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
    ],
  );
}

