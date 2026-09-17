import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Thin wrapper around the CAM FIX Spring Boot API.
///
/// Base URL: `http://localhost:8081` on every platform.
///
/// For a real device or an emulator, tunnel the port over USB first:
///     adb reverse tcp:8081 tcp:8081
///
/// Only when the phone reaches the PC over Wi-Fi instead, override with the
/// LAN IP (which also needs the firewall to allow inbound 8081):
///     flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8081
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
    // localhost everywhere, Android included. The old Android default was
    // 10.0.2.2 — the *emulator's* host alias — which is a dead address on a
    // real phone, so a build made without the dart-define silently failed with
    // "server did not respond". `adb reverse tcp:8081 tcp:8081` maps the
    // device's localhost to this PC on emulators and real devices alike.
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

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool withAuth = true,
  }) =>
      _send('DELETE', path, withAuth: withAuth);

  /// GET a JSON *array* endpoint. Non-2xx throws [ApiException] with the
  /// backend's `{"message": ...}` when present.
  Future<List<dynamic>> getJsonList(
    String path, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(withAuth: withAuth);
    final http.Response res;
    try {
      res = await _http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(0, 'The server at $baseUrl did not respond.');
    } catch (e) {
      throw ApiException(0, 'Cannot reach the server at $baseUrl. $e');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return const [];
      final decoded = jsonDecode(res.body);
      return decoded is List ? decoded : const [];
    }
    String msg = 'Request failed';
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['message'] != null) msg = j['message'].toString();
    } catch (_) {/* non-JSON body */}
    throw ApiException(res.statusCode, msg);
  }

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
        'DELETE' => _http.delete(uri, headers: headers),
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
