import 'package:flutter/material.dart';
//import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class FlowActionButton extends StatelessWidget {
  const FlowActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconSize = 28,
    this.textStyle,
    this.mainAxisSize = MainAxisSize.min,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final TextStyle? textStyle;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = textStyle ?? AppTextStyles.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: mainAxisSize,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: Center(child: icon),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: effectiveTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}