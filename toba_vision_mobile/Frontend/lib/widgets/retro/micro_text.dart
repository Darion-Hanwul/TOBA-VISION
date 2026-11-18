import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum MicroTextStyle { regular, inverted, outlined, badge }

/// Teks teknis uppercase monospace (Space Mono) untuk kode seri,
/// penanda track, tanggal perekaman, atau nomor ID ala tape-deck / walkman.
class MicroText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final Color? backgroundColor;
  final FontWeight fontWeight;
  final double letterSpacing;
  final MicroTextStyle style;
  final EdgeInsetsGeometry padding;

  const MicroText(
    this.text, {
    super.key,
    this.fontSize = 10,
    this.color,
    this.backgroundColor,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = 1.0,
    this.style = MicroTextStyle.regular,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  });

  const MicroText.regular(
    this.text, {
    super.key,
    double? fontSize,
    double? size,
    this.color,
    this.backgroundColor,
    FontWeight? fontWeight,
    FontWeight? weight,
    this.letterSpacing = 0.8,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  })  : fontSize = size ?? fontSize ?? 10,
        fontWeight = weight ?? fontWeight ?? FontWeight.w500,
        style = MicroTextStyle.regular;

  const MicroText.bold(
    this.text, {
    super.key,
    double? fontSize,
    double? size,
    this.color,
    this.backgroundColor,
    FontWeight? fontWeight,
    FontWeight? weight,
    this.letterSpacing = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  })  : fontSize = size ?? fontSize ?? 10,
        fontWeight = weight ?? fontWeight ?? FontWeight.w800,
        style = MicroTextStyle.regular;

  const MicroText.badge(
    this.text, {
    super.key,
    double? fontSize,
    double? size,
    this.color,
    this.backgroundColor,
    FontWeight? fontWeight,
    FontWeight? weight,
    this.letterSpacing = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
  })  : fontSize = size ?? fontSize ?? 10,
        fontWeight = weight ?? fontWeight ?? FontWeight.w800,
        style = MicroTextStyle.badge;

  const MicroText.inverted(
    this.text, {
    super.key,
    double? fontSize,
    double? size,
    this.color,
    this.backgroundColor,
    FontWeight? fontWeight,
    FontWeight? weight,
    this.letterSpacing = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  })  : fontSize = size ?? fontSize ?? 10,
        fontWeight = weight ?? fontWeight ?? FontWeight.w700,
        style = MicroTextStyle.inverted;

  const MicroText.outlined(
    this.text, {
    super.key,
    double? fontSize,
    double? size,
    this.color,
    this.backgroundColor,
    FontWeight? fontWeight,
    FontWeight? weight,
    this.letterSpacing = 1.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  })  : fontSize = size ?? fontSize ?? 10,
        fontWeight = weight ?? fontWeight ?? FontWeight.w700,
        style = MicroTextStyle.outlined;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (style == MicroTextStyle.inverted ? AppColors.paper : AppColors.ink);

    final textWidget = Text(
      text.toUpperCase(),
      style: AppTypography.mono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        letterSpacing: letterSpacing,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (style == MicroTextStyle.regular) {
      return textWidget;
    }

    if (style == MicroTextStyle.inverted) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.ink,
          borderRadius: BorderRadius.circular(3),
        ),
        child: textWidget,
      );
    }

    if (style == MicroTextStyle.outlined) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color ?? AppColors.ink, width: 1.2),
        ),
        child: textWidget,
      );
    }

    // Badge style (lime / orange / paper accent)
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.lime,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: textWidget,
    );
  }
}
