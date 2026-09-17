import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:camfix_app/main.dart';

void main() {
  testWidgets('App boots on the splash screen without framework errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CamFixApp());

    // Splash screen is the initial route.
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Drain the connectivity timeout and the splash delay so no test-zone
    // timers remain after the widget tree is disposed.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
