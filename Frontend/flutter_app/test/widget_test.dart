import 'package:flutter_test/flutter_test.dart';


import 'package:flutter_app/app/login_app.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    
    await tester.pumpWidget(const LoginApp());

    // Verify login screen elements
    expect(find.text('Engage Point'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}