import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/main.dart';

void main() {
  testWidgets('BOSDM Connect app test', (WidgetTester tester) async {
    await tester.pumpWidget(const ForumBrinApp());

    expect(find.text('BOSDM Connect'), findsOneWidget);
  });
}