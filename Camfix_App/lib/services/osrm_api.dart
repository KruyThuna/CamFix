import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// One road-following route from OSRM.
class OsrmRoute {
  OsrmRoute({
    required this.points,
    required this.meters,
    required this.seconds,
  });

  final List<LatLng> points;
  final double meters;
  final double seconds;

  int get minutes => (seconds / 60).round().clamp(1, 100000);
  double get km => meters / 1000;
}

class OsrmResult {
  OsrmResult(this.routes);

  /// `routes.first` is the recommended route; the rest are alternatives.
  final List<OsrmRoute> routes;
}

/// Keyless driving directions from the public OSRM demo server
/// (`router.project-osrm.org`). Returns real road geometry + distance +
/// duration + alternatives, and sends `Access-Control-Allow-Origin: *` so it
/// also works from the web build. No traffic data (OSRM has none) — the app
/// keeps its simulated traffic bands on top of the real line.
class OsrmApi {
  OsrmApi._();
  static final OsrmApi instance = OsrmApi._();

  Future<OsrmResult?> route({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&alternatives=true',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['code'] != 'Ok') return null;
      final routes = <OsrmRoute>[];
      for (final r in (body['routes'] as List)) {
        final route = r as Map<String, dynamic>;
        final coords = ((route['geometry']
            as Map<String, dynamic>)['coordinates'] as List);
        routes.add(OsrmRoute(
          points: [
            for (final c in coords)
              LatLng((c as List)[1] as double, c[0] as double),
          ],
          meters: (route['distance'] as num).toDouble(),
          seconds: (route['duration'] as num).toDouble(),
        ));
      }
      return routes.isEmpty ? null : OsrmResult(routes);
    } catch (_) {
      return null;
    }
  }
}
