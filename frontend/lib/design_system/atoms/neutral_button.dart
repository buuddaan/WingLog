import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_radius.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

enum NeutralButtonSize {
  small,
  medium,
}

class NeutralButton extends StatelessWidget {
  const NeutralButton.small({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
  }) : size = NeutralButtonSize.small;

  const NeutralButton.medium({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
  }) : size = NeutralButtonSize.medium;

  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final NeutralButtonSize size;

  bool get _isSmall => size == NeutralButtonSize.small;

  double get _height => _isSmall ? 32 : 40;
  double get _horizontalPadding => _isSmall ? 16 : 20;
  BorderRadius get _borderRadius =>
      BorderRadius.circular(_isSmall ? AppRadius.xl : AppRadius.md);

  TextStyle get _textStyle =>
      _isSmall ? AppTextStyles.label : AppTextStyles.buttonSecondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.softUi,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: AppColors.borderPrimary,
            ),
            borderRadius: _borderRadius,
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: _borderRadius,
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: _textStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}