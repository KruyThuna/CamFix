import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../theme/app_theme.dart';
import 'api_config.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.minSupportedBuild,
    required this.downloadUrl,
    required this.fileSizeMb,
    required this.forceUpdate,
    required this.releaseNotesKm,
    required this.releaseNotesEn,
  });

  final String version;
  final int buildNumber;
  final int minSupportedBuild;
  final String downloadUrl;
  final double fileSizeMb;
  final bool forceUpdate;
  final String releaseNotesKm;
  final String releaseNotesEn;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String? ?? '1.3.0',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 20,
      minSupportedBuild: (json['minSupportedBuild'] as num?)?.toInt() ?? 1,
      downloadUrl: json['downloadUrl'] as String? ??
          'https://api.camapp.store/api/app/download',
      fileSizeMb: (json['fileSizeMb'] as num?)?.toDouble() ?? 61.4,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      releaseNotesKm: json['releaseNotesKm'] as String? ?? '',
      releaseNotesEn: json['releaseNotesEn'] as String? ?? '',
    );
  }

  String releaseNotes(AppLang lang) =>
      lang == AppLang.km ? releaseNotesKm : releaseNotesEn;
}

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// Current compiled app version & build (matches pubspec.yaml: 1.3.1+21)
  static const String currentVersion = '1.3.1';
  static const int currentBuildNumber = 21;

  bool _checkedThisSession = false;

  /// Check silently on app launch (only prompts if a newer build exists)
  Future<void> checkOnStart(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    await checkForUpdate(context, silent: true);
  }

  /// Check for update manually or automatically
  Future<void> checkForUpdate(BuildContext context,
      {bool silent = false}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/app/version');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) {
        if (!silent && context.mounted) {
          _showUpToDateSnackBar(context);
        }
        return;
      }

      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final info = AppUpdateInfo.fromJson(data);

      final hasUpdate = info.buildNumber > currentBuildNumber;

      if (!context.mounted) return;

      if (hasUpdate) {
        await showDialog<void>(
          context: context,
          barrierDismissible: !info.forceUpdate,
          builder: (dialogCtx) => _buildUpdateDialog(dialogCtx, info),
        );
      } else if (!silent) {
        _showUpToDateSnackBar(context);
      }
    } catch (_) {
      if (!silent && context.mounted) {
        _showUpToDateSnackBar(context);
      }
    }
  }

  void _showUpToDateSnackBar(BuildContext context) {
    final isKm = AppSettings.instance.lang == AppLang.km;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKm
              ? 'កម្មវិធីរបស់អ្នកជាកំណែចុងក្រោយបំផុតហើយ ($currentVersion)'
              : 'You are using the latest version ($currentVersion)',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildUpdateDialog(BuildContext context, AppUpdateInfo info) {
    final isKm = AppSettings.instance.lang == AppLang.km;
    final notes = info.releaseNotes(AppSettings.instance.lang);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKm ? 'មានកំណែថ្មី!' : 'Update Available!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'v${info.version} (Build ${info.buildNumber}) · ${info.fileSizeMb} MB',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isKm ? 'អ្វីដែលថ្មីក្នុងកំណែនេះ៖' : "What's new in this version:",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                notes.isNotEmpty
                    ? notes
                    : (isKm
                        ? '• កែលម្អប្រព័ន្ធទូទាត់ប្រាក់ និងល្បឿនកម្មវិធី'
                        : '• Performance improvements and bug fixes'),
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isKm
                  ? 'សូមធ្វើបច្ចុប្បន្នភាពដើម្បីទទួលបានមុខងារថ្មីៗ និងដំណើរការល្អបំផុត។'
                  : 'Please update to get the latest features and optimal performance.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!info.forceUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isKm ? 'ពេលក្រោយ' : 'Later',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            final uri = Uri.parse(info.downloadUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                isKm ? 'អាប់ដេតឥឡូវនេះ' : 'Update Now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
