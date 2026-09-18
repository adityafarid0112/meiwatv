import 'package:flutter_test/flutter_test.dart';
import 'package:meiwastudio_app/main.dart';

void main() {
  testWidgets('MeiwaStudio app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MeiwaStudioApp());
  });
}
