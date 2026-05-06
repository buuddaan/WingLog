import 'package:flutter/material.dart';

enum AppTextVariant {
  body,
  title,
  label,
}

class AppText extends StatelessWidget {
  final String data;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText.body(
      this.data, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      }) : variant = AppTextVariant.body;

  const AppText.title(
      this.data, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      }) : variant = AppTextVariant.title;

  const AppText.label(
      this.data, {
        super.key,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
      }) : variant = AppTextVariant.label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    TextStyle? style;
    switch (variant) {
      case AppTextVariant.title:
        style = textTheme.titleLarge; // ex logga in
        break;
      case AppTextVariant.label:
        style = textTheme.labelMedium; //ex Välkommen tillbaka etc
        break;
      case AppTextVariant.body:
        style = textTheme.bodyMedium; // ex Epost, lösen
        break;
    }

    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style?.copyWith(color: color),
    );
  }
}