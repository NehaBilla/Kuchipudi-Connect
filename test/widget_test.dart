import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets(
    'Kuchipudi Connect app test',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const KuchipudiApp(),
      );

      expect(
        find.text('Kuchipudi Connect'),
        findsOneWidget,
      );
    },
  );
}