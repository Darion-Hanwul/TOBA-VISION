import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/screens/login_screen.dart';
import 'package:toba_vision_mobile/screens/register_screen.dart';

void main() {
  setUp(() {
    Services.init();
  });

  testWidgets('RegisterScreen renders fields correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const RegisterScreen(),
      ),
    );

    expect(find.text('Daftar Akun Baru'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Alamat Lahan / Lokasi Kebun'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    expect(find.text('Daftar Akun Sekarang'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });

  testWidgets('LoginScreen renders elements correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const LoginScreen(),
      ),
    );

    expect(find.text('TOBA VISION'), findsOneWidget);
    expect(find.text('v2.4 AI'), findsOneWidget);
    expect(find.text('Masuk ke Kebun'), findsOneWidget);
    expect(find.text('Daftar Akun Baru'), findsOneWidget);
    expect(find.text('Asisten AI Cerdas Petani Tembakau Modern'), findsOneWidget);
  });
}
