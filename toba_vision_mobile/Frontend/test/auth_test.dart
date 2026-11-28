import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/bmkg_locations.dart';
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

    expect(find.text('REGISTRATION // TAPE-FORM'), findsNothing);
    expect(find.text('TB-REG-2026'), findsNothing);
    expect(find.text('Data akun tersimpan aman dan terenkripsi.'), findsNothing);
    expect(find.textContaining('LUAS LAHAN KEBUN'), findsNothing);
  });

  testWidgets('RegisterScreen locks Desa field when BMKG has no village list',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const RegisterScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(BmkgLocations.getDesaList('Bulu'), isNotEmpty);
    expect(find.text('4. DESA / KELURAHAN (TERKUNCI)'), findsNothing);
    expect(find.byKey(const ValueKey('locked-desa-field')), findsNothing);

    final provDropdown = find.text('Jawa Tengah (Sentra Utama Temanggung)');
    await tester.ensureVisible(provDropdown);
    await tester.pumpAndSettle();
    await tester.tap(provDropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('DKI Jakarta').last);
    await tester.pumpAndSettle();

    final lockedFieldFinder = find.byKey(const ValueKey('locked-desa-field'));
    expect(find.text('4. DESA / KELURAHAN (TERKUNCI)'), findsOneWidget);
    expect(lockedFieldFinder, findsOneWidget);
    expect(
      find.descendant(
        of: lockedFieldFinder,
        matching: find.byIcon(Icons.lock_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('Desa belum tersedia di BMKG (terkunci)'), findsOneWidget);

    final lockedField = tester.widget<TextField>(lockedFieldFinder);
    expect(lockedField.enabled, isFalse);
    expect(lockedField.readOnly, isTrue);
    expect(lockedField.canRequestFocus, isFalse);

    await tester.enterText(lockedFieldFinder, 'Kelurahan Palsu');
    await tester.pump();
    expect(find.text('Kelurahan Palsu'), findsNothing);
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

    expect(find.text('TOBA VISION'), findsOneWidget);
    expect(find.text('MASUKAN NAMA DAN KATA SANDI ANDA'), findsOneWidget);
    expect(find.text('NAMA PETANI / USERNAME (ID UNIK)'), findsOneWidget);
    expect(find.text('KATA SANDI'), findsOneWidget);
    expect(find.textContaining('MASUK KE KEBUN'), findsOneWidget);
    expect(find.textContaining('DAFTAR AKUN BARU'), findsOneWidget);

    expect(find.text('PETANI MITRA // TB-LOGIN'), findsNothing);
    expect(find.text('TYPE 1 NORMAL POSITION'), findsNothing);
    expect(find.text('SECURE CASSETTE SYSTEM'), findsNothing);
    expect(find.text('IDENTIFICATION // MITRA RESMI'), findsNothing);
    expect(find.text('CREDENTIALS // AUTH'), findsNothing);
    expect(find.text('LOCK-PASS'), findsNothing);
    expect(find.text('V2.4 AI'), findsNothing);
    expect(find.text('Asisten AI Cerdas Petani Tembakau Modern'), findsNothing);
    expect(find.text('DEMO PETANI: Slamet Raharjo | SANDI: 123456'), findsNothing);
  });
}
