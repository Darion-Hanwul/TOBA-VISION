import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Wordmark TOBA VISION bergaya bold display retro futuristik dengan warna solid
class ChromeWordmark extends StatelessWidget {
  final double fontSize;
  final String text;
  final bool showBadge;
  final Color? color;

  const ChromeWordmark({
    super.key,
    this.fontSize = 24,
    this.text = 'TOBA VISION',
    this.showBadge = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          text,
          style: AppTypography.display(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: color ?? AppColors.ink,
          ),
        ),
        if (showBadge) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.ink, width: 1),
            ),
            child: const Text(
              'AI 2.4',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
