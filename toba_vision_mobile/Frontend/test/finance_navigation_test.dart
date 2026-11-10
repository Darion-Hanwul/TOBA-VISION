import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/screens/finance/finance_screen.dart';

void main() {
  setUp(() {
    Services.init();
  });

  testWidgets('FinanceAllMusimScreen renders Edit button and navigates to FinanceScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const FinanceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Pastikan di FinanceScreen ada chip filter "Semua"
    expect(find.text('Semua'), findsOneWidget);

    // 2. Ketuk "Semua" untuk pindah ke FinanceAllMusimScreen
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    // 3. Pastikan sudah di FinanceAllMusimScreen
    expect(find.text('Rekap Semua Musim'), findsOneWidget);
    expect(find.text('Riwayat Musim Tanam'), findsOneWidget);
    expect(find.text('Detail'), findsWidgets);
    expect(find.text('Edit'), findsWidgets);
    expect(find.text('Hapus'), findsWidgets);

    // 4. Ketuk tombol 'Edit' pertama di riwayat musim tanam
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    // 5. Pastikan terlempar/kembali ke FinanceScreen
    expect(find.text('Biaya & Pengeluaran Kebun'), findsOneWidget);
    expect(find.text('Musim Ini'), findsOneWidget);
  });
}
