import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'micro_text.dart';

/// Kartu gaya J-card / label kaset tape-deck:
/// Latar paper (#E9E6D8), border ink 2px, radius kecil (8-10), bayangan keras offset tanpa blur.
class RetroCard extends StatelessWidget {
  final Widget child;
  final String? tapeTag;
  final String? rightTag;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Offset shadowOffset;
  final VoidCallback? onTap;

  const RetroCard({
    super.key,
    required this.child,
    this.tapeTag,
    this.rightTag,
    this.backgroundColor = AppColors.paper,
    this.borderColor = AppColors.ink,
    this.shadowColor = AppColors.ink,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.radius = 10,
    this.shadowOffset = const Offset(4, 4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardBody = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tapeTag != null || rightTag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.vertical(top: Radius.circular(radius - 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tapeTag != null)
                    Expanded(
                      child: MicroText(
                        tapeTag!,
                        fontSize: 9,
                        color: AppColors.paper,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (tapeTag != null && rightTag != null)
                    const SizedBox(width: 8),
                  if (rightTag != null)
                    MicroText(
                      rightTag!,
                      fontSize: 9,
                      color: AppColors.lime,
                      fontWeight: FontWeight.w800,
                    ),
                ],
              ),
            ),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: cardBody,
      );
    }

    return cardBody;
  }
}
