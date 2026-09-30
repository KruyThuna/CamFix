import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:camfix_app/main.dart';
import 'package:camfix_app/widgets/animated_camfix_logo.dart';

void main() {
  testWidgets('App boots on the splash screen and auto-advances to language',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final messenger = tester.binding.defaultBinaryMessenger;
    const connectivity =
        MethodChannel('dev.fluttercommunity.plus/connectivity');
    const events =
        MethodChannel('dev.fluttercommunity.plus/connectivity_status');
    messenger.setMockMethodCallHandler(connectivity, (_) async => ['wifi']);
    messenger.setMockMethodCallHandler(events, (_) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(connectivity, null);
      messenger.setMockMethodCallHandler(events, null);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const CamFixApp());

      // Splash screen is the initial route.
      expect(find.byType(AnimatedCamFixLogo), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump();

      // Splash starts a 2s timer that replaces the route with /language.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Choose language'), findsOneWidget);
      expect(find.byType(AnimatedCamFixLogo), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient((_) async => http.Response('', 204)));
  });
}
