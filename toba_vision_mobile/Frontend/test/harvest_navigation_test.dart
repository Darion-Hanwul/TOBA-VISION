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
    expect(find.text('PILIH PERIODE'), findsOneWidget);
    expect(find.text('Musim Ini'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);

    // 2. Ketuk "Semua" untuk pindah ke HarvestAllMusimScreen
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    // 3. Verifikasi sudah berada di HarvestAllMusimScreen
    expect(find.text('Rekap Semua Musim Panen'), findsOneWidget);
    expect(find.text('Riwayat Musim Panen'), findsOneWidget);
    expect(find.text('Detail'), findsWidgets);
    expect(find.text('Edit'), findsWidgets);
    expect(find.text('Hapus'), findsWidgets);

    // 4. Ketuk tombol 'Edit' di kartu riwayat musim panen
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    // 5. Verifikasi terlempar/kembali ke HarvestScreen
    expect(find.text('Monitoring Siklus Panen'), findsOneWidget);
    expect(find.text('Siklus Petikan Daun'), findsOneWidget);
    expect(find.text('Musim Ini'), findsOneWidget);
  });
}
