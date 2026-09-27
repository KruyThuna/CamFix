import 'package:camfix_technician/screens/register_screen.dart';
import 'package:camfix_technician/screens/identity_verification_screen.dart';
import 'package:camfix_technician/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registration continues to identity photos without an inline SMS button', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const RegisterScreen()));
    expect(find.text('Send verification code'), findsNothing);
    await tester.tap(find.text('Next: Verify identity'));
    await tester.pump();
    // Empty phone must not trigger a network request.
    expect(find.byType(SnackBar), findsOneWidget);
    final fields = find.byType(TextField);
    const values = ['Test', 'Technician', 'test@example.com', '012345678', 'secret123', 'Phnom Penh'];
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(fields.at(i), values[i]);
    }
    await tester.tap(find.text('Next: Verify identity'));
    await tester.pumpAndSettle();
    expect(find.byType(IdentityVerificationScreen), findsOneWidget);

  });
}
