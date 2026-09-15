import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:camfix_technician/main.dart';
import 'package:camfix_technician/screens/login_screen.dart';
import 'package:camfix_technician/screens/splash_screen.dart';

void main() {
  testWidgets('boots to the splash screen, then lands on login when signed out',
      (WidgetTester tester) async {
    // SplashScreen._boot() reads the saved JWT from SharedPreferences; with
    // none stored it routes to /login rather than /home or /pending. Providing
    // a mock store also stops the plugin call from throwing in the test.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const CamFixTechApp());

    // First frame is the splash screen with its branding.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('CAM FIX'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);

    // _boot() waits 300ms, finds no token, then pushReplacement('/login').
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
