import 'dart:convert';
import 'package:camfix_app/models/service_quote.dart';
import 'package:camfix_app/screens/khqr_pay_screen.dart';
import 'package:camfix_app/services/bookings_store.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('KhqrPayScreen renders authentic Bakong stand and live Service Progress', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final booking = Booking(
      id: 101,
      category: 'Air Conditioner',
      description: 'AC Cleaning & Filter Wash',
      status: 'ASSIGNED',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      assignedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      technicianName: 'Sokha Technic',
    );

    final quote = ServiceQuote.fromJson({
      'id': 12,
      'jobId': 101,
      'status': 'ACCEPTED',
      'totalAmount': 20.60,
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: KhqrPayScreen(booking: booking, quote: quote),
      ));
      await tester.pumpAndSettle();

      // Header & Tabs
      expect(find.text('KHQR (Bakong)'), findsOneWidget);
      expect(find.text('Bakong KHQR'), findsOneWidget);
      expect(find.text('ABA Mobile'), findsOneWidget);
      expect(find.text('ACLEDA Pay'), findsOneWidget);

      // Standee Details
      expect(find.text('CamFix Field Service Co., Ltd.'), findsOneWidget);
      expect(find.text('\$20.60 USD'), findsOneWidget);
      expect(find.text('Member of'), findsOneWidget);
      expect(find.text('KHQR'), findsWidgets);

      // Action Buttons
      expect(find.text('Download QR'), findsOneWidget);
      expect(find.text('PayWay - Payment Link'), findsOneWidget);

      // Auto verification
      expect(find.text('Auto-verifying payment status...'), findsOneWidget);
      expect(find.text('I have completed payment'), findsOneWidget);

      // Embedded Service Progress
      expect(find.text('Service Progress'), findsOneWidget);
      expect(find.text('STANDARD SLA'), findsOneWidget);
      expect(find.text('Waiting Acceptance'), findsOneWidget);
      expect(find.text('Technician Traveling'), findsOneWidget);
    }, () => MockClient((request) async {
      if (request.url.path.endsWith('/khqr')) {
        return http.Response(
          jsonEncode({
            'qr': 'CAMFIX-KHQR-TEST-STRING',
            'md5': 'abc123md5hash',
            'amount': 20.60,
            'merchantName': 'CamFix Field Service Co., Ltd.',
            'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
          }),
          200,
        );
      }
      return http.Response('{"status":"PENDING"}', 200);
    }));
  });
}

