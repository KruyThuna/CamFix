import 'support/golden_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camfix_app/screens/dashboard_screen.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:camfix_app/services/bookings_store.dart';
import 'package:camfix_app/services/notifications_store.dart';

void main() {
  setUpAll(loadGoldenFonts);
  for (final width in [320.0, 430.0, 1280.0]) {
    testWidgets('Home layout at $width', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CAMFIX'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Common Fixes & Fast Booking'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_${width.toInt()}.png'));
      await tester.pumpWidget(const SizedBox.shrink());
      NotificationsStore.instance.stopPolling();
      BookingsStore.instance.stopPolling();
      await tester.pump();
    });
  }
}
