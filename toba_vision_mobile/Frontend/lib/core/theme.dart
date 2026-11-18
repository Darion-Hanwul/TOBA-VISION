import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palet Retro Y2K Walkman
  static const sage = Color(0xFF9CA882);
  static const sageDeep = Color(0xFF8A9770);
  static const ink = Color(0xFF141414);
  static const lime = Color(0xFF86D12A);
  static const limeDeep = Color(0xFF4C7A12);
  static const orange = Color(0xFFF2590F);
  static const paper = Color(0xFFE9E6D8);
  static const glass = Color(0x59EBF5E1);

  // Kompatibilitas Palet Lama (disesuaikan dengan palet retro)
  static const forest = Color(0xFF1B4019);
  static const green = Color(0xFF2F7D32);
  static const mint = Color(0xFFD4E8C2);
  static const peach = Color(0xFFFFE4D3);
  static const bg = Color(0xFF9CA882); // latar utama sage
  static const red = Color(0xFFC62828);
  static const redSoft = Color(0xFFF6D5CF);
  static const amber = Color(0xFFE08A00);
  static const amberSoft = Color(0xFFF5E3B8);
  static const muted = Color(0xFF4F5743);
  static const line = Color(0xFF141414);
}

// Kompatibilitas konstanta kSerif lama diarahkan ke font Space Grotesk / display
const kSerif = 'SpaceGrotesk';

class AppTypography {
  // Display raksasa heavy & wide (Anybody / Fallback)
  static TextStyle display({
    double? fontSize,
    double? size,
    FontWeight? fontWeight,
    FontWeight? weight,
    Color color = AppColors.ink,
    double letterSpacing = -0.5,
    double? height,
  }) {
    final effSize = size ?? fontSize ?? 28;
    final effWeight = weight ?? fontWeight ?? FontWeight.w900;
    try {
      return GoogleFonts.anybody(
        fontSize: effSize,
        fontWeight: effWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: effSize,
        fontWeight: effWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  // Microtext teknis uppercase monospace (Space Mono)
  static TextStyle mono({
    double? fontSize,
    double? size,
    FontWeight? fontWeight,
    FontWeight? weight,
    Color color = AppColors.ink,
    double letterSpacing = 0.8,
    double? height,
  }) {
    final effSize = size ?? fontSize ?? 11;
    final effWeight = weight ?? fontWeight ?? FontWeight.w700;
    try {
      return GoogleFonts.spaceMono(
        fontSize: effSize,
        fontWeight: effWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'monospace',
        fontSize: effSize,
        fontWeight: effWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  // Teks isi / body (Space Grotesk, minimal 14sp untuk keterbacaan petani)
  static TextStyle body({
    double? fontSize,
    double? size,
    FontWeight? fontWeight,
    FontWeight? weight,
    Color color = AppColors.ink,
    double? letterSpacing,
    double height = 1.4,
  }) {
    final effSize = size ?? fontSize ?? 14;
    final effWeight = weight ?? fontWeight ?? FontWeight.w500;
    try {
      return GoogleFonts.spaceGrotesk(
        fontSize: effSize,
        fontWeight: effWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: effSize,
        fontWeight: effWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }
}

ThemeData buildTheme() {
  final baseText = GoogleFonts.spaceGroteskTextTheme();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF0EFE9), // background luar frame
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      primary: AppColors.ink,
      secondary: AppColors.orange,
      surface: AppColors.paper,
    ),
    textTheme: baseText.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}

// Dekorasi RetroCard (paper + border ink 2px + hard shadow)
BoxDecoration cardDeco({
  Color color = AppColors.paper,
  Color? border,
  double radius = 10,
  Offset shadowOffset = const Offset(4, 4),
  Color? shadowColor,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? AppColors.ink, width: 2),
    boxShadow: [
      BoxShadow(
        color: shadowColor ?? AppColors.ink,
        offset: shadowOffset,
        blurRadius: 0,
      ),
    ],
  );
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat Pagi';
  if (h < 15) return 'Selamat Siang';
  if (h < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}

String rupiah(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp ${b.toString()}';
}
