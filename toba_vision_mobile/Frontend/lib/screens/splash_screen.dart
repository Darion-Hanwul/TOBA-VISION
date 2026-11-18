import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../widgets/retro/chrome_wordmark.dart';
import '../widgets/retro/glass_phone.dart';
import '../widgets/retro/marquee_text.dart';
import '../widgets/retro/micro_text.dart';
import '../widgets/retro/retro_frame.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFE9), // Latar luar frame
      body: SafeArea(
        child: GestureDetector(
          onTap: _navigateToLogin, // Ketuk layar untuk langsung melewati splash
          behavior: HitTestBehavior.opaque,
          child: RetroFrame(
            backgroundColor: AppColors.sage,
            margin: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer Aset Gambar Background (Opacity halus jika ada)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.12,
                    child: Image.asset(
                      'assets/splash screen.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Teks Raksasa Berjalan (Marquee) di belakang objek hero
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.32,
                  left: 0,
                  right: 0,
                  child: const Opacity(
                    opacity: 0.22,
                    child: MarqueeText(
                      text: 'TOBA VISION • AI AGRICULTURE • TEMANGGUNG ',
                      fontSize: 68,
                      color: AppColors.ink,
                      speed: 25,
                    ),
                  ),
                ),

                // Header Wordmark Krom di Tengah Atas
                Positioned(
                  top: 28,
                  child: Column(
                    children: [
                      const MicroText(
                        'TYPE 1 • NORMAL POSITION // AUDIO CASSETTE FEEL',
                        fontSize: 8.5,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: 6),
                      const ChromeWordmark(fontSize: 28),
                      const SizedBox(height: 4),
                      const MicroText(
                        'ASISTEN AI CERDAS PETANI TEMBAKAU MODERN',
                        fontSize: 9,
                        color: AppColors.muted,
                        letterSpacing: 1.2,
                      ),
                    ],
                  ),
                ),

                // Objek Hero SMARTPHONE Clear-Shell di Tengah
                Center(
                  child: GlassPhone(
                    width: 175,
                    height: 290,
                    rotationDegrees: 8.5,
                    animateFloat: true,
                  ),
                ),

                // Microtext Teknis di Bagian Bawah Layar
                Positioned(
                  bottom: 18,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          MicroText('TOBA-VISION v2.4 AI', fontSize: 9),
                          MicroText('TEMANGGUNG, JATENG', fontSize: 9),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const MicroText(
                        'IDENTIFICATION NUMBER - TB-2026-088',
                        fontSize: 8,
                        color: AppColors.muted,
                      ),
                    ],
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
