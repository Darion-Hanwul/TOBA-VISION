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
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const RegisterScreen(),
      ),
    );

    expect(find.text('PENDAFTARAN MITRA BARU'), findsOneWidget);
    expect(find.text('NAMA LENGKAP PETANI (ID UNIK AKUN)'), findsOneWidget);
    expect(find.text('KATA SANDI'), findsOneWidget);
    expect(find.text('KONFIRMASI KATA SANDI'), findsOneWidget);
    expect(find.textContaining('DAFTAR AKUN SEKARANG'), findsOneWidget);
  });

  testWidgets('LoginScreen renders elements correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const LoginScreen(),
      ),
    );

    expect(find.text('TOBA VISION'), findsWidgets);
    expect(find.text('V2.4 AI'), findsOneWidget);
    expect(find.textContaining('MASUK KE KEBUN'), findsOneWidget);
    expect(find.textContaining('DAFTAR AKUN BARU'), findsOneWidget);
    expect(find.text('Asisten AI Cerdas Petani Tembakau Modern'), findsOneWidget);
  });
}
