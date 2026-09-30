import 'support/golden_fonts.dart';
import 'dart:convert';
import 'package:camfix_app/models/service_provider.dart';
import 'package:camfix_app/screens/booking_sheet.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:camfix_app/l10n/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Map<String, dynamic>? submitted;
  setUpAll(loadGoldenFonts);
  for (final width in [320.0, 430.0, 1280.0]) {
    testWidgets('Booking modes, sticky confirm and payload at $width',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      submitted = null;

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () => showBookingSheet(
                            context,
                            const ServiceProvider(
                              technicianId: 7,
                              name: 'Vanna Sok',
                              category: 'Air Conditioner',
                              location: 'Phnom Penh',
                              address: '482 Industrial Avenue',
                              rating: 4.8,
                              phone: '012 222 888',
                              hasLocation: false,
                            )),
                        child: const Text('Book Now'),
                      ))),
        ));
        await tester.tap(find.text('Book Now'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                'goldens/booking_appointment_${width.toInt()}.png'));
        await tester.tap(find.text('Self Drop'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNotNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                'goldens/booking_self_drop_${width.toInt()}.png'));
        await tester.scrollUntilVisible(
            find.text(AppStrings.t('depositBreakdownCaps')), 250,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        // Compare the fee breakdown itself; arrival estimates include the
        // current minute and are checked through the booking interaction.
        await expectLater(
            find
                .ancestor(
                  of: find.text(AppStrings.t('depositBreakdownCaps')),
                  matching: find.byType(Column),
                )
                .first,
            matchesGoldenFile('goldens/booking_fees_${width.toInt()}.png'));
        await tester.scrollUntilVisible(
            find.text(AppStrings.t('customSlot')), -250,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text(AppStrings.t('customSlot')));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        await tester
            .ensureVisible(find.text(AppStrings.t('arriveImmediately')));
        await tester.tap(find.text(AppStrings.t('arriveImmediately')));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(submitted?['bookingType'], 'SELF_DROP');
        expect(submitted?['technicianId'], 7);
        expect(submitted?['address'], '482 Industrial Avenue');
        expect(submitted?['lat'], isNull);
        expect(submitted?['lng'], isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
          () => MockClient((request) async {
                if (request.method == 'POST') {
                  submitted = jsonDecode(request.body) as Map<String, dynamic>;
                  return http.Response('{"message":"Test rejection"}', 400);
                }
                return http.Response(
                    '[{"categoryId":1,"categoryName":"Air Conditioner","startingPrice":35,"benchFee":15,"travelFee":10}]',
                    200);
              }));
    });
  }
}
