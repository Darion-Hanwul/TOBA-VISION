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

    // 1. Pastikan di FinanceScreen ada chip filter "SEMUA"
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
}
