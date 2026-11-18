import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'micro_text.dart';

enum StatusChipVariant { dark, lime, orange, outlined, danger }

/// Status chip bergaya stiker teknis walkman tape-deck
class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipVariant variant;
  final IconData? icon;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.dark,
    this.icon,
    this.fontSize = 10,
  });

  const StatusChip.dark(
    this.label, {
    super.key,
    this.icon,
    this.fontSize = 10,
  }) : variant = StatusChipVariant.dark;

  const StatusChip.lime(
    this.label, {
    super.key,
    this.icon,
    this.fontSize = 10,
  }) : variant = StatusChipVariant.lime;

  const StatusChip.orange(
    this.label, {
    super.key,
    this.icon,
    this.fontSize = 10,
  }) : variant = StatusChipVariant.orange;

  const StatusChip.outlined(
    this.label, {
    super.key,
    this.icon,
    this.fontSize = 10,
  }) : variant = StatusChipVariant.outlined;

  const StatusChip.danger(
    this.label, {
    super.key,
    this.icon,
    this.fontSize = 10,
  }) : variant = StatusChipVariant.danger;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case StatusChipVariant.dark:
        bg = AppColors.ink;
        fg = AppColors.paper;
        border = Border.all(color: AppColors.ink, width: 1.5);
        break;
      case StatusChipVariant.lime:
        bg = AppColors.lime;
        fg = AppColors.ink;
        border = Border.all(color: AppColors.ink, width: 1.5);
        break;
      case StatusChipVariant.orange:
        bg = AppColors.orange;
        fg = AppColors.paper;
        border = Border.all(color: AppColors.ink, width: 1.5);
        break;
      case StatusChipVariant.outlined:
        bg = Colors.transparent;
        fg = AppColors.ink;
        border = Border.all(color: AppColors.ink, width: 1.5);
        break;
      case StatusChipVariant.danger:
        bg = AppColors.red;
        fg = AppColors.paper;
        border = Border.all(color: AppColors.ink, width: 1.5);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: border,
        boxShadow: variant != StatusChipVariant.outlined
            ? const [
                BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          MicroText(
            label,
            fontSize: fontSize,
            color: fg,
            fontWeight: FontWeight.w900,
          ),
        ],
      ),
    );
  }
}
