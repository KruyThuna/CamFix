import 'dart:io';

import 'package:flutter/services.dart';

/// Use real SDK fonts, including for widgets that use the default test font.
Future<void> loadGoldenFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ??
      'C:/IDE Support/config_android/flutter';
  for (final entry in {
    'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf'],
    'Ahem': ['roboto-regular.ttf', 'roboto-bold.ttf'],
    'MaterialIcons': ['materialicons-regular.otf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final name in entry.value) {
      final font = File('$sdk/bin/cache/artifacts/material_fonts/$name');
      loader.addFont(
          Future.value(ByteData.sublistView(await font.readAsBytes())));
    }
    await loader.load();
  }
}
