import 'package:flutter_test/flutter_test.dart';
import 'package:forum_brin_mobile/app/app.dart';
import 'package:forum_brin_mobile/features/auth/screens/splash_screen.dart';

void main() {
  testWidgets('BOSDM Connect app test', (WidgetTester tester) async {
    await tester.pumpWidget(const ForumBrinApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle();
  });
}