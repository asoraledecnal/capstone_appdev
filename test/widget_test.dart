import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_appdev/main.dart';

void main() {
  testWidgets('Wazuh SIEM login screen smoke test',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WazuhApp());

    // Verify that the login title or DICT text is rendered.
    expect(find.text('Wazuh SIEM'), findsOneWidget);
    expect(find.text('DICT Region 4A Prototype'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
