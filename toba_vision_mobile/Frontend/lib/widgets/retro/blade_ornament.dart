import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'micro_text.dart';

/// Ornamen runcing hitam (blade/swoosh/triangles) khas grafis produk retro Y2K
class BladeOrnament extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final bool flip;

  const BladeOrnament({
    super.key,
    this.width = 48,
    this.height = 12,
    this.color = AppColors.ink,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BladePainter(color: color, flip: flip),
    );
  }
}

class _BladePainter extends CustomPainter {
  final Color color;
  final bool flip;

  const _BladePainter({required this.color, required this.flip});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (!flip) {
      path.moveTo(0, size.height);
      path.lineTo(size.width * 0.7, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width * 0.85, size.height);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width * 0.3, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.15, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Titik kecil di samping blade
    final dotX = flip ? size.width * 0.05 : size.width * 0.95;
    canvas.drawCircle(Offset(dotX, size.height * 0.5), 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant _BladePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.flip != flip;
}

/// Garis divider dengan segmen tebal-tipis, segitiga runcing, dan microtext teknis opsional di tengah.
class TaperedDivider extends StatelessWidget {
  final String? centerLabel;
  final Color color;
  final double height;
  final EdgeInsetsGeometry margin;

  const TaperedDivider({
    super.key,
    this.centerLabel,
    this.color = AppColors.ink,
    this.height = 20,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      child: Row(
        children: [
          // Blade kiri
          Expanded(
            child: CustomPaint(
              painter: _TaperedLinePainter(color: color, reverse: false),
            ),
          ),
          if (centerLabel != null && centerLabel!.isNotEmpty) ...[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: MicroText(
                  centerLabel!,
                  fontSize: 9,
                  color: color,
                  style: MicroTextStyle.regular,
                ),
              ),
            ),
          ],
          // Blade kanan
          Expanded(
            child: CustomPaint(
              painter: _TaperedLinePainter(color: color, reverse: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaperedLinePainter extends CustomPainter {
  final Color color;
  final bool reverse;

  const _TaperedLinePainter({required this.color, required this.reverse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    final path = Path();

    if (!reverse) {
      // Garis menebal dari kiri ke kanan lalu runcing
      path.moveTo(0, centerY - 0.75);
      path.lineTo(size.width - 12, centerY - 1.5);
      path.lineTo(size.width, centerY);
      path.lineTo(size.width - 12, centerY + 1.5);
      path.lineTo(0, centerY + 0.75);
    } else {
      // Garis runcing dari kiri lalu menebal ke kanan
      path.moveTo(0, centerY);
      path.lineTo(12, centerY - 1.5);
      path.lineTo(size.width, centerY - 0.75);
      path.lineTo(size.width, centerY + 0.75);
      path.lineTo(12, centerY + 1.5);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Titik dekorasi
    final dotX = reverse ? 4.0 : size.width - 4.0;
    canvas.drawCircle(Offset(dotX, centerY), 1.2, paint);
  }

  @override
  bool shouldRepaint(covariant _TaperedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.reverse != reverse;
}
