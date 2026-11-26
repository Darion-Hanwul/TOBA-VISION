import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import 'retro/micro_text.dart';
import 'retro/trapezoid_tab_button.dart';
import 'retro/vu_meter_bar.dart';

/// Menampilkan hasil analisis AI offline (Deteksi Grade A/B/C atau Kematangan Siap Panen).
Future<void> showDetectionResultSheet(
  BuildContext context,
  DetectionResult result,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DetectionResultSheet(result: result),
  );
}

class _GradeVisual {
  final Color accent;
  final Color badgeBg;
  final Color badgeFg;
  final Color cardBg;

  const _GradeVisual({
    required this.accent,
    required this.badgeBg,
    required this.badgeFg,
    required this.cardBg,
  });
}

_GradeVisual _visualForCode(String code, {bool isMaturity = false}) {
  if (isMaturity) {
    switch (code) {
      case '1': // Belum Matang (Masih Muda)
        return const _GradeVisual(
          accent: AppColors.amber,
          badgeBg: AppColors.amber,
          badgeFg: AppColors.ink,
          cardBg: Color(0xFFFAF4E8),
        );
      case '2': // Matang (Siap Panen!)
        return const _GradeVisual(
          accent: AppColors.lime,
          badgeBg: AppColors.forestGreen,
          badgeFg: Colors.white,
          cardBg: Color(0xFFF1F7EA),
        );
      case '3': // Terlalu Matang
        return const _GradeVisual(
          accent: AppColors.rust,
          badgeBg: AppColors.rust,
          badgeFg: Colors.white,
          cardBg: Color(0xFFFBF0F0),
        );
      default:
        return const _GradeVisual(
          accent: AppColors.muted,
          badgeBg: AppColors.ink,
          badgeFg: AppColors.paper,
          cardBg: AppColors.paper,
        );
    }
  }

  switch (code) {
    case 'A':
      return const _GradeVisual(
        accent: AppColors.lime,
        badgeBg: AppColors.forestGreen,
        badgeFg: Colors.white,
        cardBg: Color(0xFFF1F7EA),
      );
    case 'B':
      return const _GradeVisual(
        accent: AppColors.orange,
        badgeBg: AppColors.orange,
        badgeFg: AppColors.paper,
        cardBg: Color(0xFFFAF4E8),
      );
    case 'C':
      return const _GradeVisual(
        accent: AppColors.rust,
        badgeBg: AppColors.rust,
        badgeFg: Colors.white,
        cardBg: Color(0xFFFBF0F0),
      );
    default:
      return const _GradeVisual(
        accent: AppColors.muted,
        badgeBg: AppColors.ink,
        badgeFg: AppColors.paper,
        cardBg: AppColors.paper,
      );
  }
}

IconData _maturityIconForCode(String code) {
  switch (code) {
    case '1':
      return Icons.hourglass_top_rounded;
    case '2':
      return Icons.agriculture_rounded;
    case '3':
      return Icons.warning_amber_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

class _DetectionResultSheet extends StatelessWidget {
  final DetectionResult result;

  const _DetectionResultSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final visual = _visualForCode(result.grade, isMaturity: result.isMaturity);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final hasLocalImage =
        !kIsWeb && result.imagePath != null && File(result.imagePath!).existsSync();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 40, 10, 10),
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header strip retro hitam ala Walkman
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.memory_rounded, size: 15, color: visual.accent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: MicroText(
                          result.isMaturity
                              ? 'OFFLINE TFLITE // SIAP PANEN'
                              : 'OFFLINE TFLITE // YOLO11S GRADE',
                          color: AppColors.paper,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MicroText(
                  result.inferenceMs != null ? '${result.inferenceMs} MS' : 'ON-DEVICE',
                  color: AppColors.lime,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasLocalImage) ...[
                    _buildAnnotatedImagePreview(visual),
                    const SizedBox(height: 12),
                  ],
                  _buildSummaryCard(visual),
                  if (result.isMaturity && result.classProbabilities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildMaturityBreakdown(),
                  ] else if (!result.isMaturity && result.detections.length > 1) ...[
                    const SizedBox(height: 10),
                    _buildMultiBoxBreakdown(),
                  ],
                  const SizedBox(height: 10),
                  _buildPhotoTipCard(),
                  const SizedBox(height: 14),
                  TrapezoidTabButton(
                    label: 'PINDAI DAUN LAIN',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotatedImagePreview(_GradeVisual visual) {
    final String overlayTag;
    if (result.isMaturity) {
      overlayTag = 'KLASIFIKASI KEMATANGAN • ${result.gradeName.toUpperCase()}';
    } else {
      overlayTag = result.hasDetections
          ? '${result.detections.length} DAUN TERDETEKSI'
          : 'TIDAK ADA KOTAK DETEKSI';
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(result.imagePath!),
                fit: BoxFit.contain,
              ),
              if (!result.isMaturity &&
                  result.hasDetections &&
                  result.imageWidth != null &&
                  result.imageHeight != null)
                CustomPaint(
                  painter: _TobaccoBBoxPainter(
                    detections: result.detections,
                    imageWidth: result.imageWidth!,
                    imageHeight: result.imageHeight!,
                    containerSize: constraints.biggest,
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: visual.accent, width: 1),
                    ),
                    child: MicroText(
                      overlayTag,
                      color: visual.accent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(_GradeVisual visual) {
    final confStr = result.confidencePercent != null
        ? '${result.confidencePercent!.toStringAsFixed(1)}%'
        : '0.0%';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: visual.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Kotak status utama (Huruf A/B/C untuk Grade, Ikon Panen untuk Kematangan)
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: visual.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                  ],
                ),
                child: result.isMaturity
                    ? Icon(
                        _maturityIconForCode(result.grade),
                        size: 28,
                        color: visual.badgeFg,
                      )
                    : Text(
                        result.grade,
                        style: AppTypography.display(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: visual.badgeFg,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MicroText(
                      result.badge,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: visual.badgeBg == AppColors.ink ||
                              visual.badgeBg == AppColors.amber
                          ? AppColors.ink
                          : visual.badgeBg,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.title,
                      style: AppTypography.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metaPill(
                icon: Icons.verified_rounded,
                label: 'KEYAKINAN: $confStr',
                bg: AppColors.ink,
                fg: AppColors.lime,
              ),
              _metaPill(
                icon: Icons.offline_bolt_rounded,
                label: 'OFFLINE • TANPA INTERNET',
                bg: Colors.white,
                fg: AppColors.ink,
              ),
              if (result.rawLabel != null && result.rawLabel!.isNotEmpty)
                _metaPill(
                  icon: Icons.label_outline_rounded,
                  label: 'KELAS: ${result.rawLabel!.toUpperCase()}',
                  bg: visual.accent,
                  fg: visual.accent == AppColors.lime ||
                          visual.accent == AppColors.amber
                      ? AppColors.ink
                      : Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.ink, width: 1.2),
            ),
            child: Text(
              result.description,
              style: AppTypography.body(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaturityBreakdown() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroText(
            'SKOR 3 TAHAP KEMATANGAN PANEN',
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < result.classProbabilities.length; i++) ...[
            VuMeterBar(
              value: result.classProbabilities[i].confidence,
              totalSegments: 14,
              height: 10,
              label:
                  '${result.classProbabilities[i].code}. ${result.classProbabilities[i].label.toUpperCase()}',
              valueText:
                  '${(result.classProbabilities[i].confidence * 100).toStringAsFixed(1)}%',
            ),
            if (i < result.classProbabilities.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiBoxBreakdown() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroText(
            'RINCIAN SEMUA OBJEK TERDETEKSI',
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < result.detections.length; i++)
                _metaPill(
                  icon: Icons.crop_free_rounded,
                  label:
                      '#${i + 1} GRADE ${result.detections[i].grade} (${(result.detections[i].confidence * 100).toStringAsFixed(0)}%)',
                  bg: _visualForCode(result.detections[i].grade).badgeBg,
                  fg: _visualForCode(result.detections[i].grade).badgeFg,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTipCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 17, color: AppColors.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.photoTip,
              style: AppTypography.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TobaccoBBoxPainter extends CustomPainter {
  final List<TobaccoDetectionBox> detections;
  final int imageWidth;
  final int imageHeight;
  final Size containerSize;

  _TobaccoBBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0 || size.isEmpty) return;

    final double imgAspect = imageWidth / imageHeight;
    final double boxAspect = size.width / size.height;

    final double drawW;
    final double drawH;
    final double offsetX;
    final double offsetY;

    if (imgAspect > boxAspect) {
      drawW = size.width;
      drawH = size.width / imgAspect;
      offsetX = 0.0;
      offsetY = (size.height - drawH) / 2.0;
    } else {
      drawH = size.height;
      drawW = size.height * imgAspect;
      offsetX = (size.width - drawW) / 2.0;
      offsetY = 0.0;
    }

    for (final det in detections) {
      final visual = _visualForCode(det.grade);
      final rect = Rect.fromLTRB(
        offsetX + det.left * drawW,
        offsetY + det.top * drawH,
        offsetX + det.right * drawW,
        offsetY + det.bottom * drawH,
      );

      final paint = Paint()
        ..color = visual.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(rect, paint);

      final label = 'GRADE ${det.grade} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: visual.accent == AppColors.lime ? AppColors.ink : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromLTWH(
        rect.left,
        (rect.top - tp.height - 4).clamp(0.0, size.height - tp.height - 4),
        tp.width + 8,
        tp.height + 4,
      );
      canvas.drawRect(bgRect, Paint()..color = visual.accent);
      tp.paint(canvas, Offset(bgRect.left + 4, bgRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TobaccoBBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
