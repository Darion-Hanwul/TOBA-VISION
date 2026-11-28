import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/core/theme.dart';
import 'package:toba_vision_mobile/data/bmkg_locations.dart';
import 'package:toba_vision_mobile/widgets/location_selector_sheet.dart';

void main() {
  Future<void> openPicker(
    WidgetTester tester, {
    required String activeName,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showBmkgLocationPicker(context, activeName: activeName);
              },
              child: const Text('Buka Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Picker'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mengunci kolom Desa / Kelurahan saat BMKG tidak punya rekomendasi desa',
    (WidgetTester tester) async {
      expect(BmkgLocations.getDesaList('Kecamatan Jakarta Pusat'), isEmpty);

      await openPicker(
        tester,
        activeName:
            'Desa Uji, Kec. Kecamatan Jakarta Pusat, Kab. Jakarta Pusat, Prov. DKI Jakarta',
      );

      expect(find.text('PILIH WILAYAH RESMI BMKG'), findsOneWidget);
      expect(find.text('4. DESA / KELURAHAN (TERKUNCI)'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Desa belum tersedia di BMKG (terkunci)'), findsOneWidget);

      final lockedFieldFinder = find.byKey(const ValueKey('locked-desa-field'));
      expect(lockedFieldFinder, findsOneWidget);

      final lockedField = tester.widget<TextField>(lockedFieldFinder);
      expect(lockedField.enabled, isFalse);
      expect(lockedField.readOnly, isTrue);
      expect(lockedField.canRequestFocus, isFalse);

      await tester.enterText(lockedFieldFinder, 'Kelurahan Palsu');
      await tester.pump();
      expect(find.text('Kelurahan Palsu'), findsNothing);

      expect(find.textContaining('Desa Uji'), findsNothing);
      expect(find.textContaining('Prov. DKI Jakarta'), findsOneWidget);
    },
  );

  testWidgets(
    'tetap menampilkan pilihan Desa / Kelurahan saat BMKG memiliki rekomendasi desa',
    (WidgetTester tester) async {
      expect(BmkgLocations.getDesaList('Bulu'), isNotEmpty);

      await openPicker(
        tester,
        activeName: 'Desa Bulu, Kec. Bulu, Kab. Temanggung, Prov. Jawa Tengah',
      );

      expect(find.text('PILIH WILAYAH RESMI BMKG'), findsOneWidget);
      expect(find.text('4. DESA / KELURAHAN (TERKUNCI)'), findsNothing);
      expect(find.byKey(const ValueKey('locked-desa-field')), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
      expect(find.textContaining('4. DESA / KELURAHAN ('), findsOneWidget);
      expect(
        find.text('Desa Bulu, Kec. Bulu, Kab. Temanggung, Prov. Jawa Tengah'),
        findsOneWidget,
      );
    },
  );
}
