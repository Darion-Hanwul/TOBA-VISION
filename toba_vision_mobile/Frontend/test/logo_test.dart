import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/widgets/app_logo.dart';

void main() {
  testWidgets('TobaVisionLogo renders with correct size and properties', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TobaVisionLogo(size: 64),
          ),
        ),
      ),
    );

    expect(find.byType(TobaVisionLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.maxWidth, 64);
    expect(container.constraints?.maxHeight, 64);
  });
}
