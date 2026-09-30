import 'dart:convert';
import 'package:camfix_app/models/service_provider.dart';
import 'package:camfix_app/screens/provider_detail_screen.dart';
import 'package:camfix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Achievement history refreshes completed jobs and handles errors',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completed = false;
    var fail = false;
    var historyCalls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(
              arguments: ServiceProvider(
            technicianId: 7,
            name: 'Test Technician',
            category: 'Electrical',
            location: 'Phnom Penh',
            rating: 0,
            hasLocation: false,
          )),
          builder: (_) => const ProviderDetailScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();
      expect(find.text('Completed work history'), findsOneWidget);
      expect(historyCalls, 1);
      completed = true;
      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Done · 29 Sep 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Sok Dara'), findsOneWidget);
      await tester.tap(find.byTooltip('View Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Sok Dara'), findsNWidgets(2));
      expect(find.byType(CloseButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      fail = true;
      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load work history.'), findsOneWidget);
      expect(find.text('Done · 29 Sep 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              final path = request.url.path;
              if (path.endsWith('/completed-work')) {
                historyCalls++;
                expect(request.url.queryParameters['page'], '0');
                if (fail) {
                  return http.Response('{"message":"Unavailable"}', 500);
                }
                return http.Response(
                    jsonEncode(completed
                        ? [
                            {
                              'id': 9,
                              'customerUserId': 12,
                              'customerName': 'Sok Dara',
                              'category': 'Electrical',
                              'completedAt': '2026-09-29T10:00:00'
                            }
                          ]
                        : []),
                    200);
              }
              if (path == '/api/technicians/7') {
                return http.Response(
                    jsonEncode({
                      'technicianId': 7,
                      'name': 'Test Technician',
                      'category': 'Electrical',
                      'completedJobCount': completed ? 1 : 0,
                    }),
                    200);
              }
              if (path.contains('favorite')) {
                return http.Response('{"favorite":false}', 200);
              }
              return http.Response('[]', 200);
            }));
  });
}
