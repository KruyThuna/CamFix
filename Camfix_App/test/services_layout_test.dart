import 'support/golden_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camfix_app/screens/services_screen.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:camfix_app/models/service_provider.dart';

const technicians = '''[
 {"id":2,"name":"Kruy Thuna","category":"Electrical","serviceArea":"Phnom Penh","rating":4.9,"ratingCount":1200,"available":true,"bannerTitle":"Ceiling Fan Installation & Repair","about":"Fixes rattling, wobbling, fan blade balance, regulator check & decorative fixture mounting."},
 {"id":3,"name":"Sok Dara","category":"Electrical","serviceArea":"Phnom Penh","rating":4.8,"ratingCount":950,"available":false,"bannerTitle":"MCB Breaker Tripping & Fix","about":"Emergency power outage diagnosis, circuit breaker fuse box replacement & insulation."}
]''';

void main() {
  setUpAll(loadGoldenFonts);
  for (final width in [320.0, 390.0, 430.0, 1280.0]) {
    testWidgets('Electrical service layout and booking at $width',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ServiceProvider? selected;
      await http.runWithClient(
        () => tester.pumpWidget(MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const ServicesScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/provider') {
                selected = settings.arguments as ServiceProvider;
                return MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: Text('Provider details')));
              }
              return null;
            })),
        () => MockClient((request) async => http.Response(
            request.url.path == '/api/service-prices'
                ? '[{"categoryId":2,"categoryName":"Electrical","startingPrice":35}]'
                : technicians,
            200)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Choose service category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electrical').last);
      await tester.pumpAndSettle();
      expect(find.text(categoryDescription('Electrical')), findsOneWidget);
      expect(find.text('Kruy Thuna'), findsOneWidget);
      expect(find.text('\$35'), findsWidgets);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('goldens/services_${width.toInt()}.png'));
      await tester.tap(find.byTooltip('Available technicians only'));
      await tester.pumpAndSettle();
      expect(find.text('Sok Dara'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Ceiling');
      await tester.pumpAndSettle();
      expect(find.text('Kruy Thuna'), findsOneWidget);
      await tester.ensureVisible(find.text('Book Now').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book Now').first);
      await tester.pumpAndSettle();
      expect(selected?.technicianId, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
