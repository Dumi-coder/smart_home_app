import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHomeApp());
    expect(find.byType(SmartHomeApp), findsOneWidget);
  });
}