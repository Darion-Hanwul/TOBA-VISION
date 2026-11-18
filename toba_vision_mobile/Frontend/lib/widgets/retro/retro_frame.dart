import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'grain_overlay.dart';

/// Frame sage bersudut membulat kecil (radius 10-12) dengan margin dari tepi layar
/// dan overlay grain film retro. Latar luar adalah putih gading.
class RetroFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color backgroundColor;
  final bool enableGrain;
  final bool clipContent;

  const RetroFrame({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.borderRadius = 12.0,
    this.backgroundColor = AppColors.sage,
    this.enableGrain = true,
    this.clipContent = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      color: backgroundColor,
      child: child,
    );

    if (enableGrain) {
      content = GrainOverlay(
        opacity: 0.14,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22141414),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: clipContent
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius - 2),
              child: content,
            )
          : content,
    );
  }
}
