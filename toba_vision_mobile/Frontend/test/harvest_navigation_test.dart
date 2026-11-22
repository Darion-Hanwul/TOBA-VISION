import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/screens/harvest/harvest_screen.dart';

void main() {
  setUp(() {
    Services.init();
  });

  testWidgets('HarvestScreen menampilkan tombol Musim Ini & Semua serta navigasi ke HarvestAllMusimScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const HarvestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi tombol periode muncul
    expect(find.text('PILIH PERIODE // SIKLUS'), findsOneWidget);
    expect(find.text('MUSIM INI'), findsOneWidget);
    expect(find.text('SEMUA'), findsOneWidget);

    // 2. Ketuk "SEMUA" untuk pindah ke HarvestAllMusimScreen
    await tester.tap(find.text('SEMUA'));
    await tester.pumpAndSettle();

    // 3. Verifikasi sudah berada di HarvestAllMusimScreen
    expect(find.text('REKAP SEMUA MUSIM'), findsOneWidget);
    expect(find.text('Riwayat Musim Panen'), findsOneWidget);

    if (find.text('EDIT').evaluate().isNotEmpty) {
      // 4. Ketuk tombol 'EDIT' di kartu riwayat musim panen
      await tester.tap(find.text('EDIT').first);
      await tester.pumpAndSettle();

      // 5. Verifikasi terlempar/kembali ke HarvestScreen
      expect(find.text('Siklus Petikan Daun'), findsOneWidget);
      expect(find.text('MUSIM INI'), findsOneWidget);
    }
  });
}
