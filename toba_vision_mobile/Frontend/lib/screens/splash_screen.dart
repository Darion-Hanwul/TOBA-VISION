import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  /// Durasi tampilan splash screen sebelum berpindah ke LoginScreen. Default: 2.5 detik.
  final Duration duration;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Konfigurasi status bar transparan retro (ikon gelap pada latar sage)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _timer = Timer(widget.duration, _navigateToLogin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandSage = Color(0xFFA3AB8E);
    const brandInk = Color(0xFF0E0F0C);

    return Scaffold(
      backgroundColor: brandSage,
      body: SafeArea(
        child: GestureDetector(
          onTap: _navigateToLogin, // Ketuk layar untuk langsung melewati splash
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Daun Tembakau
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: brandSage,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: brandInk.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/branding/icon_foreground.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/branding/icon_1024.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nama Aplikasi
                Text(
                  'TOBA VISION',
                  style: AppTypography.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: brandInk,
                  ),
                ),
                const SizedBox(height: 6),

                // Tagline
                Text(
                  'ASISTEN AI PETANI TEMBAKAU',
                  style: AppTypography.mono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: brandInk.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
