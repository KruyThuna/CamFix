import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'token_store.dart';

/// Thin wrapper around the CAM FIX Spring Boot API.
///
/// The dev backend runs on a PC whose LAN IP changes every time it switches
/// Wi-Fi networks, which used to mean a source edit + rebuild each time. To
/// avoid that, [baseUrl] auto-discovers the server: try the last address
/// that worked, then scan the phone's own /24 subnet on port 8081 for
/// anything answering `/api/technicians`. A firewall rule for inbound 8081
/// still has to exist on the PC - discovery only removes the need to know
/// *which* IP, not that one.
///
/// `--dart-define=API_BASE_URL=...` always wins over discovery, e.g. for
/// USB-tunnel testing:
///     flutter run --dart-define=API_BASE_URL=http://localhost:8081
///     adb reverse tcp:8081 tcp:8081
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

  /// Last resort when discovery finds nothing (e.g. not on the dev LAN at
  /// all) - keeps today's behaviour of at least trying something.
  static const String _fallback = 'http://192.168.100.35:8081';

  static const String _cacheKey = 'camfix_discovered_base_url';
  static const Duration _probeTimeout = Duration(milliseconds: 800);

  String _cachedBaseUrl = _override.isNotEmpty ? _override : _fallback;
  Future<String>? _discovery;

  /// Best-known base URL right now. Synchronous so existing sync callers
  /// (e.g. building a photo URL) keep working; it may briefly lag behind a
  /// discovery that's still running in the background on first launch.
  String get baseUrl => _cachedBaseUrl;

  /// Resolves the base URL, running LAN discovery at most once per app
  /// session (memoized) unless a build-time override is set. Capped overall
  /// so a slow/stuck discovery step can never block a request forever - a
  /// timeout just means "use whatever base URL we had" (the hardcoded
  /// fallback, if nothing better was found yet).
  Future<String> _resolveBaseUrl() {
    if (_override.isNotEmpty) return Future.value(_override);
    _discovery ??= _discover();
    return _discovery!.timeout(const Duration(seconds: 10),
        onTimeout: () => _cachedBaseUrl);
  }

  Future<String> _discover() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && await _probe(cached)) {
        _cachedBaseUrl = cached;
        return cached;
      }

      final subnet = await _localSubnetPrefix();
      if (subnet != null) {
        final found = await _scanSubnet(subnet);
        if (found != null) {
          await prefs.setString(_cacheKey, found);
          _cachedBaseUrl = found;
          return found;
        }
      }
    } catch (_) {
      // Discovery is best-effort; fall through to whatever we started with.
    }
    return _cachedBaseUrl;
  }

  Future<bool> _probe(String base) async {
    try {
      final res = await http
          .get(Uri.parse('$base/api/technicians'))
          .timeout(_probeTimeout);
      // Any real HTTP response (even an error one) means a CamFix backend
      // is there; a timeout/refused connection means it isn't.
      return res.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  /// The phone's own LAN IP's "a.b.c" prefix, straight from the OS - no
  /// location permission needed (unlike reading the WiFi SSID/info).
  ///
  /// `dart:io`'s NetworkInterface has no real implementation on Flutter Web
  /// (it hangs rather than throwing), so skip discovery there entirely - the
  /// web build is only used for local preview/testing anyway.
  Future<String?> _localSubnetPrefix() async {
    if (kIsWeb) return null;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4 && _isPrivate(parts)) {
            return parts.take(3).join('.');
          }
        }
      }
    } catch (_) {/* no usable interface */}
    return null;
  }

  static bool _isPrivate(List<String> octets) {
    final a = int.tryParse(octets[0]) ?? -1;
    final b = int.tryParse(octets[1]) ?? -1;
    return a == 10 || a == 192 || (a == 172 && b >= 16 && b <= 31);
  }

  /// Probes all 254 hosts on [prefix] concurrently in small batches so a
  /// full scan takes a couple of seconds instead of minutes.
  Future<String?> _scanSubnet(String prefix) async {
    const batchSize = 32;
    for (var start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final results = await Future.wait([
        for (var i = start; i <= end; i++) _probeHost('$prefix.$i'),
      ]);
      for (final hit in results) {
        if (hit != null) return hit;
      }
    }
    return null;
  }

  Future<String?> _probeHost(String ip) async {
    final base = 'http://$ip:8081';
    return await _probe(base) ? base : null;
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
    final base = await _resolveBaseUrl();
    final uri = Uri.parse('$base$path');
    final headers = await _headers(withAuth: withAuth);
    final http.Response res;
    try {
      res = await _http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(0, 'The server at $base did not respond.');
    } catch (e) {
      throw ApiException(0, 'Cannot reach the server at $base. $e');
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
    final base = await _resolveBaseUrl();
    final uri = Uri.parse('$base$path');
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
        'The server at $base did not respond. Make sure this device and the '
        'CamFix PC are on the same Wi-Fi network, the backend is running, '
        'and the PC firewall allows inbound port 8081.',
      );
    } catch (e) {
      throw ApiException(0, 'Cannot reach the server at $base. $e');
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
