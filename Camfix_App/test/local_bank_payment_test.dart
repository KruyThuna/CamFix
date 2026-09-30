import 'package:camfix_app/models/service_quote.dart';
import 'package:camfix_app/screens/khqr_pay_screen.dart';
import 'package:camfix_app/screens/payment_method_screen.dart';
import 'package:camfix_app/screens/payment_summary_screen.dart';
import 'package:camfix_app/services/bookings_store.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  var bankEnabled = false;
  var starts = 0;
  for (final enabled in [false, true]) {
    testWidgets('Local bank uses KHQR only when enabled: $enabled',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      starts = 0;
      bankEnabled = enabled;
      final quote = ServiceQuote.fromJson(
          {'id': 8, 'jobId': 5, 'status': 'ACCEPTED', 'totalAmount': 15});
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: PaymentMethodScreen(
            booking: const Booking(
                id: 5,
                category: 'Electrical',
                description: 'Repair',
                status: 'IN_PROGRESS'),
            quote: quote,
            breakdown: PaymentBreakdown.fromQuote(quote),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('Apple Pay'), findsNothing);
        expect(find.text('AC / ABA Local Bank'), findsOneWidget);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(starts, enabled ? 1 : 0);
        expect(find.byType(KhqrPayScreen),
            enabled ? findsOneWidget : findsNothing);
        if (!enabled) {
          expect(
              find.text(
                  'Local bank payment is currently unavailable. Please try again later.'),
              findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
          () => MockClient((request) async {
                if (request.url.path.endsWith('/khqr/config')) {
          return http.Response('{"enabled":$bankEnabled}', 200);
                }
                expect(request.url.path, '/api/bookings/5/quotes/8/khqr');
                starts++;
                return http.Response('{"message":"Test QR unavailable"}', 503);
              }));
    });
  }
}
