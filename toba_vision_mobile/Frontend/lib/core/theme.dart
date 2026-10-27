import 'package:flutter/material.dart';

class AppColors {
  static const forest = Color(0xFF0B4A2A);
  static const green = Color(0xFF1B6B3A);
  static const mint = Color(0xFFD4F5DF);
  static const peach = Color(0xFFFFE4D3);
  static const bg = Color(0xFFF8FAFC);
  static const red = Color(0xFFC62828);
  static const redSoft = Color(0xFFFDE3E3);
  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFFF4E5);
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
}

const kSerif = 'serif';

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.forest,
      surface: Colors.white,
    ),
  );
}

BoxDecoration cardDeco({Color color = Colors.white, Color? border, double radius = 24}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: border == null ? null : Border.all(color: border),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 3)),
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
