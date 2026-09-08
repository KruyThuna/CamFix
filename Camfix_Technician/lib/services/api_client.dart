import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Thin wrapper around the CAM FIX Spring Boot API.
///
/// Base URL resolution (override with `--dart-define=API_BASE_URL=...`):
///  - Android emulator  -> http://10.0.2.2:8081  (host loopback alias)
///  - iOS sim / desktop / web -> http://localhost:8081
///  - REAL Android/iOS device -> MUST pass your PC's LAN IP, e.g.
///    `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8081`
///    (10.0.2.2 / localhost do not exist on a physical phone — the request
///    just hangs and you get "Cannot reach the server. TimeoutException".)
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class _CacheEntry {
  _CacheEntry(this.body, this.etag, this.expiresAt);
  final Map<String, dynamic> body;
  final String? etag;
  final DateTime expiresAt;
  bool get isFresh => expiresAt.isAfter(DateTime.now());
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  final http.Client _http = http.Client();

  /// In-memory response cache for [getJson] calls made with a non-zero
  /// `ttl`. Cleared on login/logout ([clearCache]) so nothing leaks across
  /// accounts sharing a device; otherwise lives only for the app session.
  final _cache = <String, _CacheEntry>{};

  /// Drop everything cached. Call this whenever the signed-in identity
  /// changes (new token stored, or signed out) -- see `AuthApi._storeToken`
  /// and `ProfileScreen._logout`.
  void clearCache() => _cache.clear();

  /// Forget the cached GET response(s) for one path -- across whichever
  /// token(s) they were cached under -- e.g. after a mutation that makes
  /// it stale (`invalidate('/api/auth/me')` after `PUT /api/auth/me`).
  void invalidate(String path) =>
      _cache.removeWhere((key, _) => key.startsWith('GET $path#'));

  /// GET a JSON *array* endpoint (no caching). Non-2xx throws [ApiException]
  /// with the backend's `{"message": ...}` when present.
  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(withAuth: withAuth);
    final http.Response res;
    try {
      res = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(0, 'The server at $baseUrl did not respond.');
    } catch (e) {
      throw ApiException(0, 'Cannot reach the server at $baseUrl. $e');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = res.body.isEmpty ? const [] : jsonDecode(res.body);
      return decoded is List
          ? decoded.whereType<Map<String, dynamic>>().toList()
          : const [];
    }
    String msg = 'Request failed';
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['message'] != null) msg = j['message'].toString();
    } catch (_) {}
    throw ApiException(res.statusCode, msg);
  }

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await TokenStore.instance.read();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) =>
      _send('POST', path, body: body, withAuth: withAuth);

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) =>
      _send('PUT', path, body: body, withAuth: withAuth);

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) =>
      _send('PATCH', path, body: body, withAuth: withAuth);

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) =>
      _send('DELETE', path, body: body, withAuth: withAuth);

  /// `ttl` > `Duration.zero` serves a cached response instantly if it's
  /// still fresh, and otherwise revalidates with `If-None-Match` (a 304
  /// keeps the cached body and just refreshes its expiry, so an unchanged
  /// resource costs a cheap round trip instead of a full re-download). A
  /// network failure with a stale-but-present cache entry serves that
  /// entry rather than surfacing the error -- fine for read-mostly data
  /// like a profile, not something you'd want for a balance/price check.
  Future<Map<String, dynamic>> getJson(
    String path, {
    bool withAuth = true,
    Duration ttl = Duration.zero,
  }) =>
      _send('GET', path, withAuth: withAuth, ttl: ttl);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
    Duration ttl = Duration.zero,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(withAuth: withAuth);

    // Keyed by the token actually used for this call (not just the path):
    // a slow request made under an old token that resolves *after* a
    // newer one (e.g. app-launch preload racing a fresh login) then
    // writes to its own key instead of clobbering the new token's entry.
    final cacheKey = '$method $path#${headers['Authorization'] ?? ''}';
    final cacheable = method == 'GET' && ttl > Duration.zero;
    final cached = cacheable ? _cache[cacheKey] : null;
    if (cached != null && cached.isFresh) return cached.body;
    if (cached?.etag != null) headers['If-None-Match'] = cached!.etag!;

    final http.Response res;
    try {
      final f = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'PUT' => _http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
        'PATCH' => _http.patch(uri, headers: headers, body: jsonEncode(body ?? {})),
        'DELETE' => _http.delete(uri, headers: headers, body: jsonEncode(body ?? {})),
        _ => _http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      };
      res = await f.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      if (cached != null) return cached.body; // stale beats nothing
      throw ApiException(
        0,
        'The server at $baseUrl did not respond. On a real device run the app '
        "with --dart-define=API_BASE_URL=http://<your-PC-IP>:8081 (and check "
        'the PC and phone share a Wi-Fi network / the firewall allows port 8081).',
      );
    } catch (e) {
      if (cached != null) return cached.body;
      throw ApiException(0, 'Cannot reach the server at $baseUrl. $e');
    }

    if (res.statusCode == 304 && cached != null) {
      _cache[cacheKey] = _CacheEntry(cached.body, cached.etag, DateTime.now().add(ttl));
      return cached.body;
    }

    Map<String, dynamic> json = const {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {/* non-JSON body */}
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (cacheable) {
        _cache[cacheKey] =
            _CacheEntry(json, res.headers['etag'], DateTime.now().add(ttl));
      }
      return json;
    }

    final msg =
        (json['message'] ?? json['error'] ?? res.reasonPhrase ?? 'Request failed')
            .toString();
    throw ApiException(res.statusCode, msg);
  }
}
