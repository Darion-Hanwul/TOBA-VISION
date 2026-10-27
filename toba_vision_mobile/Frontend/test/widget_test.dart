import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TobaVisionApp());
  });
}
