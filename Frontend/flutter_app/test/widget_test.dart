import 'package:flutter_test/flutter_test.dart';

// Try these different import options:

// Option 1: If LoginApp is in main.dart

// Option 2: If LoginApp is in a separate file
import 'package:flutter_app/app/login_app.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const LoginApp());

    // Verify login screen elements
    expect(find.text('Engage Point'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}