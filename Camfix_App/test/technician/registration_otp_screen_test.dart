import 'package:camfix_app/technician/screens/registration_otp_screen.dart';
import 'package:camfix_app/technician/services/api_client.dart';
import 'package:camfix_app/technician/theme/app_theme.dart';
import 'package:camfix_app/technician/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'OTP fits a narrow screen, supports paste and keeps provider errors visible',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.reset);
    String? code;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: RegistrationOtpScreen(
          phone: '012345678',
          onVerify: (value) async {
            code = value;
            throw ApiException(401, 'Invalid or expired verification code');
          }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('012345678'), findsOneWidget);
    expect(tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull);
    final resend = find.widgetWithText(TextButton, 'Resend code (1:00)');
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify & create account'));
    await tester.pumpAndSettle();
    expect(code, '123456');
    expect(find.text('Invalid or expired verification code'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('successful verification returns to registration',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RegistrationOtpScreen(
                            phone: '012345678', onVerify: (_) async {})));
              },
              child: const Text('Start')),
        )));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.ensureVisible(find.text('Verify & create account'));
    await tester.tap(find.text('Verify & create account'));
    await tester.pumpAndSettle();
    expect(result, true);
  });
}
