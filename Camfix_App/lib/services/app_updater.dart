import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Checks GitHub Releases for new APK builds and prompts the user to auto-update.
abstract final class AppUpdater {
  static const String currentVersion = '1.3.0+19';
  static const String repoOwner = 'KruyThuna';
  static const String repoName = 'CamFix';

  /// Direct permanent APK link
  static const String fallbackDownloadUrl =
      'https://github.com/$repoOwner/$repoName/releases/latest/download/Camfix_App.apk';

  /// Checks GitHub API for the latest release.
  /// If [showNoUpdateSnack] is true, shows "App is up to date" when no new release.
  static Future<void> check(
    BuildContext context, {
    bool showNoUpdateSnack = false,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        if (showNoUpdateSnack && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not check for updates.')),
          );
        }
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final latestTag = (data['tag_name'] ?? data['name'] ?? '').toString();

      // Find APK asset download URL
      String apkUrl = fallbackDownloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null && assets.isNotEmpty) {
        for (final a in assets) {
          if (a is Map<String, dynamic> &&
              (a['name'] ?? '').toString().endsWith('.apk')) {
            apkUrl = a['browser_download_url'] ?? fallbackDownloadUrl;
            break;
          }
        }
      }

      // Check if latest version differs from current version
      final isNewer = _isNewerVersion(latestTag, currentVersion);
      if (!context.mounted) return;

      if (isNewer) {
        _showUpdateDialog(context, latestTag, apkUrl);
      } else if (showNoUpdateSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are using the latest version ($currentVersion).'),
          ),
        );
      }
    } catch (_) {
      if (showNoUpdateSnack && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check for updates.')),
        );
      }
    }
  }

  static bool _isNewerVersion(String latestTag, String current) {
    if (latestTag.isEmpty) return false;
    final cleanLatest = latestTag.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleanLatest.isEmpty || cleanCurrent.isEmpty) return false;
    return cleanLatest != cleanCurrent;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String newVersion,
    String downloadUrl,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of Camfix ($newVersion) is available.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Update now to get the latest features, improvements, and bug fixes.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update Now'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
