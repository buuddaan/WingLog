import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'PlusJakartaSans';

  static const TextStyle header1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700, //Bold
    color: AppColors.textPrimary,
  );

  static const TextStyle header2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700, //Bold
    color: AppColors.textPrimary,
  );

  static const TextStyle header3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600, //Semibold
    color: AppColors.textPrimary,
  );

  static const TextStyle header4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600, //Semibold
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400, //Regular
    color: AppColors.textPrimary,
  );

  static const TextStyle microCopy = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500, //Medium
    color: AppColors.textPrimary,
  );

  static const TextStyle microCopyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700, //Bold
    color: AppColors.textPrimary,
  );
}