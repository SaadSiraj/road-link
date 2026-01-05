import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AppText extends StatelessWidget {
  final String? text;
  final TextSpan? textSpan;

  // Core styling
  final double? size;
  final Color? color;
  final FontWeight? fontWeight;
  final String? fontFamily; // optional

  // Layout
  final TextAlign? align;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;

  // Decorations
  final TextDecoration? decoration;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;

  // Style extras
  final FontStyle? fontStyle;
  final TextBaseline? textBaseline;

  const AppText(
    this.text, {
    super.key,
    this.textSpan,
    this.size,
    this.color,
    this.fontWeight,
    this.fontFamily,
    this.align,
    this.overflow,
    this.maxLines,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.fontStyle,
    this.textBaseline,
  }) : assert(
         text != null || textSpan != null,
         'Either text or textSpan must be provided',
       );

  /// Factory constructor for rich text with TextSpan
  factory AppText.rich(
    TextSpan textSpan, {
    Key? key,
    TextAlign? align,
    TextOverflow? overflow,
    int? maxLines,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
  }) {
    return AppText(
      null,
      key: key,
      textSpan: textSpan,
      align: align,
      overflow: overflow,
      maxLines: maxLines,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: size ?? 14,
      color: color ?? AppColors.textPrimary,
      fontWeight: fontWeight ?? FontWeight.normal,
      fontFamily: "SpaceGrotesk",
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
    );

    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        textAlign: align ?? TextAlign.start,
        overflow: overflow,
        maxLines: maxLines,
        style: defaultStyle,
      );
    }

    return Text(
      text!,
      textAlign: align ?? TextAlign.start,
      overflow: overflow,
      maxLines: maxLines,
      style: defaultStyle,
    );
  }
}
