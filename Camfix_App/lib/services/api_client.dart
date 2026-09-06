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

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool withAuth = true,
  }) =>
      _send('GET', path, withAuth: withAuth);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(withAuth: withAuth);
    final http.Response res;
    try {
      final f = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'PUT' => _http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
        _ => _http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      };
      res = await f.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(
        0,
        'The server at $baseUrl did not respond. On a real device run the app '
        "with --dart-define=API_BASE_URL=http://<your-PC-IP>:8081 (and check "
        'the PC and phone share a Wi-Fi network / the firewall allows port 8081).',
      );
    } catch (e) {
      throw ApiException(0, 'Cannot reach the server at $baseUrl. $e');
    }

    Map<String, dynamic> json = const {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (_) {/* non-JSON body */}
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    final msg =
        (json['message'] ?? json['error'] ?? res.reasonPhrase ?? 'Request failed')
            .toString();
    throw ApiException(res.statusCode, msg);
  }
}
