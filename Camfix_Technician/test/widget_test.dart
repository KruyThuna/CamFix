import 'package:flutter_test/flutter_test.dart';

import 'package:camfix_technician/main.dart';

void main() {
  testWidgets('app boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CamFixTechApp());
    expect(find.text('CAM FIX'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);
  });
}
