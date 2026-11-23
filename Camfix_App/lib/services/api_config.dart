import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the single backend base URL used by every app role.
/// Supports in-app device storage so users and devices can connect from any network.
abstract final class ApiConfig {
  // v3 automatically purges legacy or local-IP URLs saved by previous versions.
  static const String _storageKey = 'custom_api_base_url_v3';
  static const String _legacyV2Key = 'custom_api_base_url_v2';
  static const String _legacyV1Key = 'custom_api_base_url';
  static String? _savedUrl;

  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Custom domain configured for production
  static const String domainUrl = 'https://api.camonline.store';

  /// Public API exposed through the named Cloudflare tunnel.
  static const String liveTunnelUrl = domainUrl;

  /// Stable release endpoint backed by the named Cloudflare tunnel.
  static const String defaultProductionUrl = domainUrl;

  /// Loads saved custom server URL from device storage on launch.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear values written by releases that used temporary Cloudflare URLs or local IPs.
      await prefs.remove(_legacyV1Key);
      await prefs.remove(_legacyV2Key);
      _savedUrl = prefs.getString(_storageKey);
      // On real mobile devices, localhost, 127.0.0.1, or LAN IPs cannot reach the public server.
      if (!kIsWeb && _savedUrl != null) {
        final lower = _savedUrl!.toLowerCase();
        if (lower.contains('127.0.0.1') ||
            lower.contains('localhost') ||
            lower.contains('10.0.2.2') ||
            lower.contains('192.168.')) {
          await prefs.remove(_storageKey);
          _savedUrl = null;
        }
      }
    } catch (_) {}
  }

  /// The active base URL.
  static String get baseUrl {
    // 1. Prioritize user's custom URL saved on device storage
    if (_savedUrl != null && _savedUrl!.trim().isNotEmpty) {
      final url = _savedUrl!.trim();
      // On real mobile devices, ignore localhost / LAN loopbacks
      if (!kIsWeb) {
        final lower = url.toLowerCase();
        if (lower.contains('127.0.0.1') ||
            lower.contains('localhost') ||
            lower.contains('10.0.2.2') ||
            lower.contains('192.168.')) {
          return defaultProductionUrl;
        }
      }
      return url;
    }

    // 2. Compile-time override passed via --dart-define=API_BASE_URL=...
    if (_override.isNotEmpty) return _override;

    // 3. All builds use the public API unless explicitly overridden.
    if (kDebugMode && kIsWeb) {
      return 'http://127.0.0.1:8081';
    }

    return defaultProductionUrl;
  }

  /// Save or change the server URL directly on the phone
  static Future<void> setCustomUrl(String? url) async {
    final clean = url?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    _savedUrl = clean.isEmpty ? null : clean;
    final prefs = await SharedPreferences.getInstance();
    if (_savedUrl == null) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, _savedUrl!);
    }
  }

  static String? get customUrl => _savedUrl;
}
