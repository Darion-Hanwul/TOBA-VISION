import 'package:flutter/material.dart';

/// Logo resmi aplikasi TOBA VISION.
/// 
/// Menggambar logo vektor presisi tinggi sesuai brand identity:
/// - Squircle background warna hijau hutan tembakau (#29543C)
/// - Siluet daun tembakau putih minimalis bersudut 45 derajat
/// - Garis celah urat daun (vein slit) berkontur halus
/// - Aksen lingkaran jingga/terakota matang (#E08442) di kanan bawah
class TobaVisionLogo extends StatelessWidget {
  /// Ukuran sisi persegi logo (lebar dan tinggi sama). Default: 48.
  final double size;

  /// Radius sudut lengkung squircle. Jika null, otomatis proporsional (0.233 * size).
  final double? borderRadius;

  /// Menampilkan latar squircle hijau atau hanya siluet motifnya saja. Default: true.
  final bool showBackground;

  /// Warna latar squircle. Default: Color(0xFF29543C).
  final Color backgroundColor;

  /// Warna daun. Default: Colors.white.
  final Color leafColor;

  /// Warna titik aksen jingga Sindoro. Default: Color(0xFFE08442).
  final Color dotColor;

  /// Daftar bayangan (box shadow) opsional untuk efek taktil/elevasi.
  final List<BoxShadow>? elevation;

  const TobaVisionLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.showBackground = true,
    this.backgroundColor = const Color(0xFF29543C),
    this.leafColor = Colors.white,
    this.dotColor = const Color(0xFFE08442),
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? (size * 0.233);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground ? backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/Logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: Size(size, size),
          painter: _TobaVisionLogoPainter(
            backgroundColor: backgroundColor,
            leafColor: leafColor,
            dotColor: dotColor,
            showBackground: showBackground,
          ),
        ),
      ),
    );
  }
}

class _TobaVisionLogoPainter extends CustomPainter {
  final Color backgroundColor;
  final Color leafColor;
  final Color dotColor;
  final bool showBackground;

  const _TobaVisionLogoPainter({
    required this.backgroundColor,
    required this.leafColor,
    required this.dotColor,
    required this.showBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Gambar siluet daun putih (dua kurva kubik Bezier presisi)
    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leafPath = Path();

    // Titik ujung bawah-kiri (Tip 1)
    final p0 = Offset(w * 0.2930, h * 0.7061);

    // Titik ujung atas-kanan (Tip 2)
    final p3 = Offset(w * 0.7139, h * 0.2891);

    // Kurva atas-kiri (Upper-left arc)
    final p1 = Offset(w * 0.2515, h * 0.4150);
    final p2 = Offset(w * 0.4613, h * 0.2680);

    // Kurva bawah-kanan (Lower-right arc)
    final p4 = Offset(w * 0.7327, h * 0.5815);
    final p5 = Offset(w * 0.5478, h * 0.7464);

    leafPath.moveTo(p0.dx, p0.dy);
    leafPath.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    leafPath.cubicTo(p4.dx, p4.dy, p5.dx, p5.dy, p0.dx, p0.dy);
    leafPath.close();

    canvas.drawPath(leafPath, leafPaint);

    // 2. Gambar celah garis urat daun tengah (vein slit) kapsul melengkung
    final slitPaint = Paint()
      ..color = showBackground ? backgroundColor : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0456
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final slitStart = Offset(w * 0.3315, h * 0.6694);
    final slitEnd = Offset(w * 0.6147, h * 0.3862);

    canvas.drawLine(slitStart, slitEnd, slitPaint);

    // 3. Gambar lingkaran jingga terakota di kanan-bawah daun
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final dotCenter = Offset(w * 0.6871, h * 0.6871);
    final dotRadius = w * 0.0659;

    canvas.drawCircle(dotCenter, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TobaVisionLogoPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.leafColor != leafColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.showBackground != showBackground;
  }
}
