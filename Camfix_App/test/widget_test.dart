import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:camfix_app/main.dart';

void main() {
  testWidgets('App boots on the splash screen and auto-advances to language',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CamFixApp());

    // Splash screen is the initial route.
    expect(find.byIcon(Icons.location_on), findsOneWidget);

    // Splash starts a 2s timer that replaces the route with /language.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsNothing);
  });
}
