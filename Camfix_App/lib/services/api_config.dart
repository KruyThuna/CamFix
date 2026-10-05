import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the single backend base URL used by every app role.
/// Supports in-app device storage so users and devices can connect from any network.
abstract final class ApiConfig {
  // v2 intentionally invalidates server URLs saved by older APKs. Those APKs
  // could persist short-lived trycloudflare.com or LAN addresses and keep
  // using them even after a release was built with the permanent hostname.
  static const String _storageKey = 'custom_api_base_url_v2';
  static const String _legacyStorageKey = 'custom_api_base_url';
  static String? _savedUrl;

  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Custom domain configured for production
  static const String domainUrl = 'https://api.camapp.store';

  /// Public API exposed through the named Cloudflare tunnel.
  static const String liveTunnelUrl = domainUrl;

  /// Stable release endpoint backed by the named Cloudflare tunnel.
  static const String defaultProductionUrl = domainUrl;

  /// Loads saved custom server URL from device storage on launch.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear values written by releases that used temporary Cloudflare URLs.
      await prefs.remove(_legacyStorageKey);
      _savedUrl = prefs.getString(_storageKey);
    } catch (_) {}
  }

  /// The active base URL.
  static String get baseUrl {
    // 1. Prioritize user's custom URL saved on device storage
    if (_savedUrl != null && _savedUrl!.trim().isNotEmpty) {
      return _savedUrl!.trim();
    }

    // 2. Compile-time override passed via --dart-define=API_BASE_URL=...
    if (_override.isNotEmpty) return _override;

    // 3. All builds use the public API unless explicitly overridden.
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
