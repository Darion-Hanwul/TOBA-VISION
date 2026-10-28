import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'register_screen.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(text: 'Slamet Raharjo');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Mode Slicing: Langsung navigasi ke HomeScreen (Shell) tanpa cek input
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Shell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero & Brand Identity Card
              _buildHeroBrandCard(),
              const SizedBox(height: 16),

              // 2. Form Card: Nama & Kata Sandi
              _buildFormCard(),
              const SizedBox(height: 20),

              // 3. Primary Button: Masuk ke Kebun
              _buildLoginButton(),
              const SizedBox(height: 24),

              // 4. Footer: Daftar Akun Baru
              _buildFooterLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBrandCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High Contrast Tactile App Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF004C22),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004C22).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(40, 40),
                painter: _TobaccoLeafPainter(),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Identity Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'TOBA VISION',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDBCA),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                            'v2.4 AI',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF331200),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Asisten AI Cerdas Petani Tembakau Modern',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF404940),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input 1: Nama Lengkap / Akun Petani
          const Text(
            'Nama Lengkap / Akun Petani',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Masukkan nama terdaftar',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF707A6F)),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Color(0xFF004C22),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input 2: Kata Sandi
          const Text(
            'Kata Sandi',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Masukkan kata sandi',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF707A6F)),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: Color(0xFF004C22),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF707A6F),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  tooltip: 'Lihat atau sembunyikan kata sandi',
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF004C22),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0xFF004C22).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _handleLogin,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Masuk ke Kebun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Belum punya akun? ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF404940),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004C22),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Color(0xFF004C22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for tobacco leaf icon with tactile green vector look
class _TobaccoLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = const Color(0xFFA6F4B7)
      ..style = PaintingStyle.fill;

    final veinPaint = Paint()
      ..color = const Color(0xFF004C22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = const Color(0xFFFD8A42)
      ..style = PaintingStyle.fill;

    final path = Path();
    // Central tobacco leaf silhouette
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.cubicTo(
      size.width * 0.85,
      size.height * 0.25,
      size.width * 0.9,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.9,
    );
    path.cubicTo(
      size.width * 0.1,
      size.height * 0.7,
      size.width * 0.15,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.1,
    );
    path.close();
    canvas.drawPath(path, leafPaint);

    // Center vein
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.18),
      Offset(size.width * 0.5, size.height * 0.85),
      veinPaint,
    );

    // Side veins
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.72, size.height * 0.32),
      veinPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.28, size.height * 0.32),
      veinPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.55),
      Offset(size.width * 0.72, size.height * 0.48),
      veinPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.55),
      Offset(size.width * 0.28, size.height * 0.48),
      veinPaint,
    );

    // Accent dot (peach/orange) representing Sindoro sunrise / maturity
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.22),
      3.5,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
