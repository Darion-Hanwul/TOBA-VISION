import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/data/services.dart';
import 'package:toba_vision_mobile/main.dart';

void main() {
  setUp(() {
    Services.init();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TobaVisionApp());
    await tester.pumpAndSettle();
  });
}
