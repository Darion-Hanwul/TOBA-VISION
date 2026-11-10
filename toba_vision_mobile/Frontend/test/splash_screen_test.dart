import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/screens/login_screen.dart';
import 'package:toba_vision_mobile/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen menampilkan asset gambar dan berpindah ke LoginScreen setelah durasi',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          duration: Duration(milliseconds: 500),
        ),
      ),
    );

    // Verifikasi SplashScreen menampilkan widget Image dengan asset splash screen.png
    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect((imageWidget.image as AssetImage).assetName, 'assets/splash screen.png');

    // Menunggu durasi timer splash selesai dan animasi transisi selesai
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verifikasi navigasi ke LoginScreen berhasil
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('SplashScreen dapat diketuk untuk langsung melewati ke LoginScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          duration: Duration(seconds: 5),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    // Ketuk layar
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    // Verifikasi langsung berpindah ke LoginScreen tanpa menunggu 5 detik
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
