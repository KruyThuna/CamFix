import 'dart:convert';
import 'package:camfix_app/screens/booking_tracking_screen.dart';
import 'package:camfix_app/screens/payment_summary_screen.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Unpaid tracking can reopen payment after Back and hides it when paid',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var paid = false;
    var paymentChecks = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(arguments: 5),
          builder: (_) => const BookingTrackingScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      final payButton = find.widgetWithText(FilledButton, 'Pay Now');
      await tester.scrollUntilVisible(payButton, 300);
      await tester.tap(payButton);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentSummaryScreen), findsOneWidget);
      expect(
          tester
              .widget<PaymentSummaryScreen>(find.byType(PaymentSummaryScreen))
              .quote
              .id,
          8);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(payButton);
      await tester.tap(payButton);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentSummaryScreen), findsOneWidget);
      paid = true;
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(payButton, findsNothing);
      expect(paymentChecks, greaterThanOrEqualTo(4));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
        () => MockClient((request) async {
              final path = request.url.path;
              if (path == '/api/bookings/5') {
                return http.Response(
                    jsonEncode({
                      'id': 5,
                      'category': 'Electrical',
                      'status': 'IN_PROGRESS',
                      'bookingType': 'SELF_DROP',
                      'description': 'Repair',
                    }),
                    200);
              }
              if (path.endsWith('/quotes')) {
                return http.Response(
                    jsonEncode([
                      {
                        'id': 8,
                        'jobId': 5,
                        'technicianId': 7,
                        'status': 'ACCEPTED',
                        'totalAmount': 27,
                        'laborCost': 27,
                      }
                    ]),
                    200);
              }
              if (path.endsWith('/payment')) {
                paymentChecks++;
                return http.Response(
                    jsonEncode(paid
                        ? {
                            'jobId': 5,
                            'quoteId': 8,
                            'serviceRef': 'CF-5',
                            'totalAmount': 30.37,
                          }
                        : {}),
                    200);
              }
              return http.Response('[]', 200);
            }));
  });
}
