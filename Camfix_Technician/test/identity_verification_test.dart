import 'dart:convert';

import 'package:camfix_technician/screens/identity_verification_screen.dart';
import 'package:camfix_technician/screens/selfie_camera_screen.dart';
import 'package:camfix_technician/theme/app_theme.dart';
import 'package:camfix_technician/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 1000.0]) {
    testWidgets('verification fits $width width and blocks incomplete submission', (tester) async {
      tester.view.reset();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
          home: const IdentityVerificationScreen(email: 'test@example.com')));
      await tester.pumpAndSettle();
      expect(find.text('Identity card'), findsOneWidget);
      expect(find.text('Face photo'), findsOneWidget);
      final submit = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(submit.onPressed, isNull);
      final idPosition = tester.getTopLeft(find.text('Identity card'));
      final facePosition = tester.getTopLeft(find.text('Face photo'));
      if (width < 680) {
        expect(facePosition.dy, greaterThan(idPosition.dy));
      } else {
        expect(facePosition.dy, idPosition.dy);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('both photos enable submission and are returned to registration', (tester) async {
    final image = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF1sAAAAASUVORK5CYII=');
    IdentityPhotos? result;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Builder(
      builder: (context) => TextButton(onPressed: () async {
        result = await Navigator.push<IdentityPhotos>(context, MaterialPageRoute(
          builder: (_) => IdentityVerificationScreen(email: 'test@example.com',
              initial: IdentityPhotos(image, facePhoto: image))));
      }, child: const Text('Start')),
    )));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Submit for verification'), 300);
    await tester.tap(find.text('Submit for verification'));
    await tester.pumpAndSettle();
    expect(result?.idCard, image);
    expect(result?.facePhoto, image);
  });

  testWidgets('unavailable camera shows retry instead of allowing capture', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/camera');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async => <Map<String, Object>>[]);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light,
        home: const SelfieCameraScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Try camera again'), 300);
    expect(find.text('Try camera again'), findsOneWidget);
    expect(find.text('Take face photo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
