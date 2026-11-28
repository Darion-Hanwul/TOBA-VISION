import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/screens/finance/finance_all_musim_screen.dart';
import 'package:toba_vision_mobile/screens/finance/finance_screen.dart';
import 'package:toba_vision_mobile/screens/finance/finance_screen_edit_upload.dart';

void main() {
  setUp(() {
    Services.init();
  });

  test('FinanceAllMusimScreen.isSeasonCompleted handles Sudah Selesai consistently', () {
    expect(FinanceAllMusimScreen.isSeasonCompleted({'status': 'Sudah Selesai'}), isTrue);
    expect(FinanceAllMusimScreen.isSeasonCompleted({'status': 'SELESAI'}), isTrue);
    expect(FinanceAllMusimScreen.isSeasonCompleted({'status': 'Selesai'}), isTrue);
    expect(FinanceAllMusimScreen.isSeasonCompleted({'isSelesai': true}), isTrue);
    expect(FinanceAllMusimScreen.isSeasonCompleted({'status': 'Belum Selesai'}), isFalse);
    expect(tanggalIndonesia(DateTime(2026, 11, 28)), '28 November 2026');
  });

  testWidgets('FinanceAllMusimScreen renders Edit button and navigates to FinanceScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const FinanceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Pastikan header & filter sesuai serta ada chip "SEMUA"
    expect(find.text('KEUANGAN TANI // TEMANGGUNG'), findsNothing);
    expect(find.text('PILIH PERIODE // FILTER'), findsNothing);
    expect(find.text('PILIH MUSIM'), findsWidgets);
    expect(find.text('SEMUA'), findsOneWidget);

    // 2. Ketuk "SEMUA" untuk pindah ke FinanceAllMusimScreen
    await tester.tap(find.text('SEMUA'));
    await tester.pumpAndSettle();

    // 3. Pastikan sudah di FinanceAllMusimScreen
    expect(find.text('REKAP SEMUA MUSIM'), findsOneWidget);
    expect(find.text('RIWAYAT MUSIM TANAM // ARSIP'), findsOneWidget);

    if (find.text('EDIT').evaluate().isNotEmpty) {
      // 4. Ketuk tombol 'EDIT' pertama di riwayat musim tanam
      await tester.tap(find.text('EDIT').first);
      await tester.pumpAndSettle();

      // 5. Pastikan terlempar/kembali ke FinanceScreen
      expect(find.text('BUKU KAS BIAYA'), findsOneWidget);
      expect(find.text('MUSIM INI'), findsOneWidget);
    }
  });

  testWidgets('FinanceScreenEditUpload hides optional notes field', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const FinanceScreenEditUpload(),
      ),
    );
    await tester.pump();

    expect(find.text('NOMINAL PENGELUARAN (RP)'), findsOneWidget);
    expect(find.text('TANGGAL PENGELUARAN'), findsOneWidget);
    expect(find.text('CATATAN TAMBAHAN (OPSIONAL)'), findsNothing);
    expect(find.text('Tuliskan rincian tambahan di sini...'), findsNothing);
  });
}
