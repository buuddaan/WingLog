import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: subtitle != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.header3,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: AppTextStyles.body,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}