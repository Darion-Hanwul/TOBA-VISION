import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'micro_text.dart';

/// Progress bar bergaya equalizer / VU meter tape-deck dengan 12-20 segmen bertingkat:
/// Warna transisi dari Lime -> Orange -> Merah di ujung kanan.
class VuMeterBar extends StatelessWidget {
  /// Nilai 0.0 sampai 1.0 (atau lebih dari 1.0)
  final double value;
  final int totalSegments;
  final double height;
  final String? label;
  final String? valueText;

  const VuMeterBar({
    super.key,
    required this.value,
    this.totalSegments = 16,
    this.height = 16,
    this.label,
    this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final activeSegments = (clamped * totalSegments).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || valueText != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Expanded(
                  child: MicroText(label!, fontSize: 9, color: AppColors.ink),
                )
              else
                const SizedBox.shrink(),
              if (label != null && valueText != null)
                const SizedBox(width: 8),
              if (valueText != null)
                MicroText(
                  valueText!,
                  fontSize: 10,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
            ],
          ),
          const SizedBox(height: 5),
        ],
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: Row(
            children: List.generate(totalSegments, (index) {
              final isActive = index < activeSegments;

              // Skema warna segmen:
              // Segmen 0 - 65% : Lime
              // Segmen 65% - 85% : Orange
              // Segmen 85% - 100% : Red
              final ratio = index / totalSegments;
              Color activeColor;
              if (ratio < 0.65) {
                activeColor = AppColors.lime;
              } else if (ratio < 0.85) {
                activeColor = AppColors.orange;
              } else {
                activeColor = AppColors.red;
              }

              return Expanded(
                child: Container(
                  height: height,
                  margin: EdgeInsets.only(
                    right: index == totalSegments - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : const Color(0xFF2B3322),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
