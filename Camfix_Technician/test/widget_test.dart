import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:camfix_technician/main.dart';
import 'package:camfix_technician/screens/language_screen.dart';
import 'package:camfix_technician/screens/splash_screen.dart';

void main() {
  testWidgets(
      'boots to the splash screen, then lands on language selection when signed out',
      (WidgetTester tester) async {
    // SplashScreen._boot() reads the saved JWT from SharedPreferences; with
    // none stored it routes to /language rather than /home or /pending.
    // Providing a mock store also stops the plugin call from throwing in the
    // test.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const CamFixTechApp());

    // First frame is the splash screen with its branding.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('CAM FIX'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);

    // _boot() waits 1.2s, finds no token, then replaces the splash route.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LanguageScreen), findsOneWidget);
  });
}
