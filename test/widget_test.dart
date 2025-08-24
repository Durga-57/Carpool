// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:carpool_app/main.dart'; // Make sure this path is correct

void main() {
  testWidgets('Auth screen displays login form initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We use CarpoolAuthApp now, not MyApp.
    await tester.pumpWidget(const CarpoolAuthApp());

    // Verify that the LOGIN title is present.
    expect(find.text('LOGIN'), findsOneWidget);

    // Verify that the SIGN UP title is not present initially.
    expect(find.text('SIGN UP'), findsNothing);
  });
}