import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Overlay noise/grain film ringan yang di-cache menggunakan RepaintBoundary
/// agar tidak membebani render frame pada perangkat menengah.
class GrainOverlay extends StatelessWidget {
  final double opacity;
  final Widget? child;

  const GrainOverlay({
    super.key,
    this.opacity = 0.12,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (child != null) child!,
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: const RepaintBoundary(
                child: CustomPaint(
                  painter: _StaticGrainPainter(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticGrainPainter extends CustomPainter {
  const _StaticGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paintLight = Paint()..color = Colors.white.withValues(alpha: 0.18);
    final paintDark = Paint()..color = Colors.black.withValues(alpha: 0.22);

    // Gunakan pseudorandom generator dengan fixed seed agar deterministik dan tidak repaint terus-menerus
    final random = math.Random(42);
    const int step = 6; // Grid kerapatan titik
    final cols = (size.width / step).ceil();
    final rows = (size.height / step).ceil();

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final randVal = random.nextDouble();
        if (randVal < 0.25) {
          final x = i * step + random.nextDouble() * step;
          final y = j * step + random.nextDouble() * step;
          canvas.drawCircle(Offset(x, y), 0.75, randVal < 0.12 ? paintDark : paintLight);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
