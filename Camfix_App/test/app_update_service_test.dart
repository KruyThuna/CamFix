import 'package:flutter_test/flutter_test.dart';
import 'package:camfix_app/services/app_update_service.dart';
import 'package:camfix_app/app_settings.dart';

void main() {
  group('AppUpdateInfo', () {
    test('parses JSON correctly with Khmer and English notes', () {
      final json = {
        'version': '1.3.1',
        'buildNumber': 21,
        'minSupportedBuild': 1,
        'downloadUrl': 'https://api.camapp.store/api/app/download',
        'fileSizeMb': 61.4,
        'forceUpdate': false,
        'releaseNotesKm': '• កែលម្អប្រព័ន្ធទូទាត់ប្រាក់',
        'releaseNotesEn': '• Improved payment system',
      };

      final info = AppUpdateInfo.fromJson(json);

      expect(info.version, '1.3.1');
      expect(info.buildNumber, 21);
      expect(info.fileSizeMb, 61.4);
      expect(info.forceUpdate, isFalse);
      expect(info.releaseNotes(AppLang.km), '• កែលម្អប្រព័ន្ធទូទាត់ប្រាក់');
      expect(info.releaseNotes(AppLang.en), '• Improved payment system');
    });

    test('handles default fallback values on partial JSON', () {
      final info = AppUpdateInfo.fromJson({});

      expect(info.version, '1.3.0');
      expect(info.buildNumber, 20);
      expect(info.forceUpdate, isFalse);
      expect(info.downloadUrl, contains('/api/app/download'));
    });
  });
}

