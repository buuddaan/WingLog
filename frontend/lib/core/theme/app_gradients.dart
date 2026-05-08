import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient loginBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
    ],
  );

  static const LinearGradient googleButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
    ],
  );
}