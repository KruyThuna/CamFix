import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodeResult {
  const GeocodeResult(
      {required this.displayName, required this.lat, required this.lng});
  final String displayName;
  final double lat;
  final double lng;
}

/// Forward/reverse geocoding via OpenStreetMap's Nominatim - free, no API key,
/// matching the map tiles' own "no API key" setup. Nominatim's usage policy
/// (https://operations.osmfoundation.org/policies/nominatim) asks for a real
/// User-Agent identifying the app and roughly one request/second, which
/// debounced interactive typing naturally respects.
class GeocodingApi {
  GeocodingApi._();
  static final GeocodingApi instance = GeocodingApi._();

  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'CamFixApp/1.0 (student project)'};

  /// Place-name search, biased to Cambodia (CamFix only operates there).
  /// Returns an empty list on any failure - search is a convenience on top
  /// of tap-to-pick/current-location, never something that should block the
  /// picker.
  Future<List<GeocodeResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': q,
      'format': 'jsonv2',
      'limit': '6',
      'countrycodes': 'kh',
    });
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((j) => GeocodeResult(
                displayName: (j['display_name'] ?? '').toString(),
                lat: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
                lng: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
              ))
          .where((r) => r.displayName.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Coordinates → a human-readable address, for showing something better
  /// than raw "lat, lng" once a point is picked (by tap or GPS). Null on
  /// failure - callers fall back to the coordinates.
  Future<String?> reverse(double lat, double lng) async {
    final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
      'lat': '$lat',
      'lon': '$lng',
      'format': 'jsonv2',
    });
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['display_name'] != null) {
        return decoded['display_name'].toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
