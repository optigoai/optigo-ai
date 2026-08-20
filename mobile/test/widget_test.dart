import 'package:flutter_test/flutter_test.dart';
import 'package:optigoai_app/app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OptigoAIApp());
    expect(find.text('OptigoAI'), findsOneWidget);
  });
}
