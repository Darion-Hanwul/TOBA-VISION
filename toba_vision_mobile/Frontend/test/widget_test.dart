import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/main.dart';
import 'package:toba_vision_mobile/screens/home_screen.dart';

void main() {
  setUp(() {
    Services.init();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TobaVisionApp());
    await tester.pumpAndSettle();
  });

  testWidgets('HomeScreen hides removed header/track/TB-SYS tags', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(onNavigate: (_) {}),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Deteksi AI'), findsOneWidget);
    expect(find.text('Cuaca Kebun'), findsOneWidget);
    expect(find.text('Keuangan'), findsOneWidget);
    expect(find.text('Panen'), findsOneWidget);

    expect(find.text('TEMANGGUNG, JATENG // POKTAN'), findsNothing);
    expect(find.text('TRACK 01'), findsNothing);
    expect(find.text('TRACK 02'), findsNothing);
    expect(find.text('TRACK 03'), findsNothing);
    expect(find.text('TRACK 04'), findsNothing);
    expect(find.text('TB-SYS'), findsNothing);
  });
}
