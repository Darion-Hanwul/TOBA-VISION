import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'micro_text.dart';

/// Objek hero SMARTPHONE clear-shell (plastik transparan dengan tint hijau lime,
/// sedikit miring ~8-10 derajat) yang layarnya menampilkan bingkai viewfinder
/// dan siluet daun tembakau bergradien. Mendukung parameter opsional [imageProvider].
class GlassPhone extends StatefulWidget {
  final double width;
  final double height;
  final double rotationDegrees;
  final ImageProvider? imageProvider;
  final bool animateFloat;

  const GlassPhone({
    super.key,
    this.width = 170,
    this.height = 280,
    this.rotationDegrees = 8.5,
    this.imageProvider,
    this.animateFloat = true,
  });

  @override
  State<GlassPhone> createState() => _GlassPhoneState();
}

class _GlassPhoneState extends State<GlassPhone> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    if (widget.animateFloat) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final rad = (widget.rotationDegrees * math.pi) / 180;

    Widget phoneContent;

    if (widget.imageProvider != null) {
      phoneContent = Image(
        image: widget.imageProvider!,
        fit: BoxFit.contain,
        width: widget.width,
        height: widget.height,
      );
    } else {
      phoneContent = _buildPureVectorGlassPhone();
    }

    if (disableAnimations || !widget.animateFloat) {
      return Transform.rotate(
        angle: rad,
        child: phoneContent,
      );
    }

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: rad,
            child: phoneContent,
          ),
        );
      },
    );
  }

  Widget _buildPureVectorGlassPhone() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        // Plastik transparan clear-shell dengan tint hijau lime
        color: const Color(0x3386D12A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xCC86D12A), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44141414),
            offset: Offset(8, 12),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x2286D12A),
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xCC141414), // Layar bagian dalam gelap
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Refleksi kaca diagonal
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: _GlassReflectionPainter(),
                ),
              ),
            ),

            // Siluet daun tembakau di layar
            CustomPaint(
              size: Size(widget.width * 0.55, widget.height * 0.45),
              painter: _TobaccoLeafSilhouettePainter(),
            ),

            // Viewfinder reticle (sudut siku lime)
            CustomPaint(
              size: Size(widget.width * 0.65, widget.height * 0.55),
              painter: _ReticleCornerPainter(),
            ),

            // Stiker label kertas gading kecil di bodi (ala tape-deck)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppColors.ink, width: 1),
                ),
                child: const MicroText(
                  'MODEL TB-24 AI',
                  fontSize: 7,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassReflectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x33FFFFFF),
          Color(0x05FFFFFF),
          Colors.transparent,
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TobaccoLeafSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.lime, AppColors.limeDeep],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Bentuk daun tembakau elegan
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(size.width * 0.95, size.height * 0.35, size.width * 0.5, size.height);
    path.quadraticBezierTo(size.width * 0.05, size.height * 0.35, size.width * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Tulang daun tengah
    final veinPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width * 0.5, 6), Offset(size.width * 0.5, size.height - 4), veinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReticleCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const cornerLen = 14.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(Offset(size.width, 0), const Offset(0, cornerLen), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
