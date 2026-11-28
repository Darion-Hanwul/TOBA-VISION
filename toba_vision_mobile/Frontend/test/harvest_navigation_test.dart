import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/screens/harvest/harvest_all_musim_screen.dart';
import 'package:toba_vision_mobile/screens/harvest/harvest_screen.dart';

void main() {
  setUp(() {
    Services.init();
  });

  test('HarvestAllMusimScreen.formatTanggalIndonesia formats day, month, and year', () {
    expect(
      HarvestAllMusimScreen.formatTanggalIndonesia(DateTime(2026, 11, 28)),
      '28 November 2026',
    );
    expect(
      HarvestAllMusimScreen.formatTanggalIndonesia(DateTime(2024, 5, 10)),
      '10 Mei 2024',
    );
  });

  test('isHarvestStepReadOnly locks previously saved steps for inline edit', () {
    expect(
      isHarvestStepReadOnly(activeStep: 1, unlockedStep: 3, hasSavedRecord: true),
      isTrue,
    );
    expect(
      isHarvestStepReadOnly(activeStep: 2, unlockedStep: 3, hasSavedRecord: false),
      isTrue,
    );
    expect(
      isHarvestStepReadOnly(activeStep: 3, unlockedStep: 3, hasSavedRecord: false),
      isFalse,
    );
    expect(
      isHarvestStepReadOnly(activeStep: 7, unlockedStep: 7, hasSavedRecord: true),
      isTrue,
    );
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

    // 1. Verifikasi tombol periode muncul dan kolom kondisi daun sudah dihapus
    expect(find.text('PILIH PERIODE'), findsOneWidget);
    expect(find.text('PILIH PERIODE // SIKLUS'), findsNothing);
    expect(find.text('LAHAN BLOK A • TEMANGGUNG'), findsNothing);
    expect(find.text('MUSIM INI'), findsOneWidget);
    expect(find.text('SEMUA'), findsOneWidget);
    expect(find.text('KETERANGAN / KONDISI DAUN'), findsNothing);

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
