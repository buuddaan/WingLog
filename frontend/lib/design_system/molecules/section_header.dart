import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_spacing.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = AppSpacing.xxs,
    this.centerTitle = false,
    this.height = 56,
    this.sideSlothWidth = 48,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool centerTitle;
  final double height;
  final double sideSlothWidth;

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final Widget titleBlock = Column(
      crossAxisAlignment:
      centerTitle ? CrossAxisAlignment.center : crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          style: titleStyle ?? AppTextStyles.header3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_hasSubtitle) ...[
          SizedBox(height: spacing),
          Text(
            subtitle!,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: subtitleStyle ?? AppTextStyles.body,
          ),
        ],
      ],
    );

    final content = SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: sideSlothWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: leading,
            ),
          ),
        Expanded(
            child: centerTitle ? Center(
            child: titleBlock) : Align(
              alignment: Alignment.centerLeft,
              child: titleBlock,
            ),
        ),

       SizedBox(
         width: sideSlothWidth,
         child: Align(
           alignment: Alignment.centerRight,
           child: trailing,
         ),
       ),
      ],
      ),
    );

    if (padding != null) {
      return Padding(
          padding: padding!,
          child: content,
      );
    }
    return content;
  }
}