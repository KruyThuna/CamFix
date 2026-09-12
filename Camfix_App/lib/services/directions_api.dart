import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// One driving route from the Google Directions API.
class DirectionsRoute {
  DirectionsRoute({
    required this.points,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    required this.summary,
  });

  /// The road-following polyline, decoded from `overview_polyline`.
  final List<LatLng> points;
  final String distanceText; // e.g. "17.5 km"
  final int distanceMeters;
  final String durationText; // e.g. "27 min" (traffic-aware when available)
  final int durationSeconds;
  final String summary; // e.g. "National Road 4"
}

class DirectionsResult {
  DirectionsResult(this.routes);

  /// `routes.first` is Google's recommended route; the rest are alternatives.
  final List<DirectionsRoute> routes;
}

/// Thin wrapper over `https://maps.googleapis.com/maps/api/directions/json`.
///
/// Needs `--dart-define=GOOGLE_MAPS_API_KEY=...` and the **Directions API**
/// enabled on that key. Works on Android/iOS; on web Google blocks the call
/// with CORS, so callers should fall back to a drawn route there.
class DirectionsApi {
  DirectionsApi._();
  static final DirectionsApi instance = DirectionsApi._();

  static const String _key =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  bool get configured => _key.isNotEmpty && !kIsWeb;

  Future<DirectionsResult?> route({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (!configured) return null;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'alternatives': 'true',
      'mode': 'driving',
      'departure_time': 'now', // ask for traffic-aware duration
      'key': _key,
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 'OK') return null;
      final routes = <DirectionsRoute>[];
      for (final r in (body['routes'] as List)) {
        final route = r as Map<String, dynamic>;
        final leg = (route['legs'] as List).first as Map<String, dynamic>;
        final dur = (leg['duration_in_traffic'] ?? leg['duration'])
            as Map<String, dynamic>;
        final dist = leg['distance'] as Map<String, dynamic>;
        routes.add(DirectionsRoute(
          points: decodePolyline(
              (route['overview_polyline'] as Map<String, dynamic>)['points']
                  as String),
          distanceText: dist['text'] as String,
          distanceMeters: (dist['value'] as num).toInt(),
          durationText: dur['text'] as String,
          durationSeconds: (dur['value'] as num).toInt(),
          summary: (route['summary'] as String?) ?? '',
        ));
      }
      return routes.isEmpty ? null : DirectionsResult(routes);
    } catch (_) {
      return null;
    }
  }

  /// Google's [encoded polyline algorithm](https://developers.google.com/maps/documentation/utilities/polylinealgorithm).
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
