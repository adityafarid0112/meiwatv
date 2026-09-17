import 'package:flutter_test/flutter_test.dart';
import 'package:meiwatv_app/main.dart';

void main() {
  testWidgets('MeiwaTvApp smoke test - renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(const MeiwaTvApp());
    expect(find.text('MEIWA'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
  });
}
