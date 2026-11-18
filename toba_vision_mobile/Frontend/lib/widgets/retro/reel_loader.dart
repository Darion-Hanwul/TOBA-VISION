import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Indikator loading bergaya dua reel kaset pita yang berputar serentak.
class ReelLoader extends StatefulWidget {
  final double size;
  final Color color;
  final String? label;

  const ReelLoader({
    super.key,
    this.size = 36,
    this.color = AppColors.ink,
    this.label,
  });

  @override
  State<ReelLoader> createState() => _ReelLoaderState();
}

class _ReelLoaderState extends State<ReelLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return _buildStaticReel();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildReelVisual(_controller.value * 2 * math.pi);
      },
    );
  }

  Widget _buildStaticReel() {
    return _buildReelVisual(0.0);
  }

  Widget _buildReelVisual(double angle) {
    final reelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ReelPainter(angle: angle, color: widget.color),
        ),
        SizedBox(width: widget.size * 0.35),
        CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ReelPainter(angle: angle, color: widget.color),
        ),
      ],
    );

    if (widget.label != null && widget.label!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          reelWidget,
          const SizedBox(height: 8),
          Text(
            widget.label!.toUpperCase(),
            style: AppTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: widget.color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      );
    }

    return reelWidget;
  }
}

class _ReelPainter extends CustomPainter {
  final double angle;
  final Color color;

  const _ReelPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final hubPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Lingkaran luar kaset
    canvas.drawCircle(center, radius - 1, rimPaint);

    // Hub tengah kaset
    canvas.drawCircle(center, radius * 0.38, hubPaint);
    canvas.drawCircle(center, radius * 0.16, Paint()..color = AppColors.paper);

    // 3 atau 6 gigi roda kaset
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final toothPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final rad = i * (2 * math.pi / 3);
      final p1 = Offset(math.cos(rad) * radius * 0.38, math.sin(rad) * radius * 0.38);
      final p2 = Offset(math.cos(rad) * (radius - 3), math.sin(rad) * (radius - 3));
      canvas.drawLine(p1, p2, toothPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReelPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.color != color;
}
