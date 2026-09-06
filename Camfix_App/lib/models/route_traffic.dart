import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// How a stretch of road is flowing. [unknown] means the map has no live
/// traffic data for that stretch ("unmarked" / not mapped).
enum TrafficLevel { free, moderate, heavy, blocked, unknown }

extension TrafficLevelX on TrafficLevel {
  Color get color => switch (this) {
        TrafficLevel.free => const Color(0xFF34A853),
        TrafficLevel.moderate => const Color(0xFFF9AB00),
        TrafficLevel.heavy => const Color(0xFFE8710A),
        TrafficLevel.blocked => const Color(0xFFD93025),
        TrafficLevel.unknown => const Color(0xFF9AA0A6),
      };

  String get labelKey => switch (this) {
        TrafficLevel.free => 'trafficFree',
        TrafficLevel.moderate => 'trafficModerate',
        TrafficLevel.heavy => 'trafficHeavy',
        TrafficLevel.blocked => 'trafficBlocked',
        TrafficLevel.unknown => 'trafficUnknown',
      };

  /// Demo metres/second the technician covers on this kind of road. Not a real
  /// speed — tuned so the sample trip plays out in about a minute, with the
  /// slow / blocked stretches clearly slower than the clear ones.
  double get speed => switch (this) {
        TrafficLevel.free => 55,
        TrafficLevel.moderate => 28,
        TrafficLevel.heavy => 11,
        TrafficLevel.blocked => 0,
        TrafficLevel.unknown => 35,
      };
}

/// One colour-coded stretch of the live route.
class RouteSegment {
  const RouteSegment(this.points, this.level);
  final List<LatLng> points;
  final TrafficLevel level;
}

/// One selectable route (the live one, or a greyed alternative), with the
/// numbers Google shows next to it.
class RouteOption {
  RouteOption(this.points, this.meters, this.minutes, this._labelFrac);
  final List<LatLng> points;
  final double meters;
  final int minutes;
  final double _labelFrac;

  double get km => meters / 1000;

  /// Where to hang the "X min · Y km" pill so the routes' pills don't collide.
  LatLng get labelAnchor {
    final i =
        (points.length * _labelFrac).round().clamp(0, points.length - 1);
    return points[i];
  }
}

/// A curved, densified origin→destination route split into traffic bands, two
/// greyed alternatives, and the helpers the live map needs to slide a marker
/// along the main route and report conditions ahead.
class TrafficRoute {
  TrafficRoute._({
    required this.points,
    required this.segments,
    required this.cumMeters,
    required this.totalMeters,
    required this.center,
    required this.fitZoom,
    required this.alts,
    required this.mainMinutes,
  });

  final List<LatLng> points;
  final List<RouteSegment> segments;
  final List<double> cumMeters; // one entry per point
  final double totalMeters;
  final LatLng center;
  final double fitZoom;

  /// Two dimmer "you could also go this way" routes.
  final List<RouteOption> alts;

  /// Estimated minutes for the live route.
  final int mainMinutes;

  double get mainKm => totalMeters / 1000;

  LatLng get mainLabelAnchor {
    final i = (points.length * 0.36).round().clamp(0, points.length - 1);
    return points[i];
  }

  static const Distance _dist = Distance();

  /// ~24 km/h city pace, used to turn a length into a believable ETA.
  static const double _metresPerMin = 400;

  static const List<({double frac, TrafficLevel level})> _bands = [
    (frac: 0.00, level: TrafficLevel.free),
    (frac: 0.26, level: TrafficLevel.moderate),
    (frac: 0.44, level: TrafficLevel.heavy),
    (frac: 0.58, level: TrafficLevel.blocked),
    (frac: 0.68, level: TrafficLevel.unknown),
    (frac: 0.84, level: TrafficLevel.free),
  ];

  factory TrafficRoute.build(LatLng origin, LatLng destination) {
    final dLat = destination.latitude - origin.latitude;
    final dLng = destination.longitude - origin.longitude;
    final len = math.sqrt(dLat * dLat + dLng * dLng);
    final pLat = len == 0 ? 0.0 : -dLng / len; // unit perpendicular
    final pLng = len == 0 ? 0.0 : dLat / len;

    LatLng at(double f, double off) => LatLng(
          origin.latitude + dLat * f + pLat * off,
          origin.longitude + dLng * f + pLng * off,
        );

    List<LatLng> densify(List<LatLng> ways, int perLeg) {
      final out = <LatLng>[];
      for (var i = 0; i < ways.length - 1; i++) {
        final a = ways[i], b = ways[i + 1];
        for (var s = 0; s < perLeg; s++) {
          final f = s / perLeg;
          out.add(LatLng(
            a.latitude + (b.latitude - a.latitude) * f,
            a.longitude + (b.longitude - a.longitude) * f,
          ));
        }
      }
      out.add(ways.last);
      return out;
    }

    double lengthOf(List<LatLng> line) {
      var m = 0.0;
      for (var i = 1; i < line.length; i++) {
        m += _dist(line[i - 1], line[i]);
      }
      return m;
    }

    // Main (live) route: gentle S-curve.
    final pts = densify([
      origin,
      at(0.18, 0.0016),
      at(0.36, -0.0011),
      at(0.52, 0.0009),
      at(0.68, -0.0018),
      at(0.84, 0.0006),
      destination,
    ], 12);

    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum[i - 1] + _dist(pts[i - 1], pts[i]));
    }
    final total = cum.last;

    // Alternative A: swings one way and wider. Alternative B: the other way.
    final altA = densify([
      origin,
      at(0.24, -0.0020),
      at(0.50, -0.0034),
      at(0.76, -0.0018),
      destination,
    ], 14);
    final altB = densify([
      origin,
      at(0.20, 0.0026),
      at(0.46, 0.0044),
      at(0.74, 0.0030),
      destination,
    ], 14);
    final altALen = lengthOf(altA);
    final altBLen = lengthOf(altB);

    int minutesFor(double metres, double drag) =>
        math.max(1, (metres / _metresPerMin * drag).round());

    final alts = <RouteOption>[
      RouteOption(altA, altALen, minutesFor(altALen, 1.05), 0.56),
      RouteOption(altB, altBLen, minutesFor(altBLen, 1.10), 0.44),
    ];

    // Split the main route into continuous, colour-coded segments.
    final bounds = <int>[0];
    for (var b = 1; b < _bands.length; b++) {
      final m = _bands[b].frac * total;
      var idx = 0;
      while (idx < pts.length - 1 && cum[idx] < m) {
        idx++;
      }
      bounds.add(idx);
    }
    bounds.add(pts.length - 1);

    final segs = <RouteSegment>[];
    for (var b = 0; b < _bands.length; b++) {
      final s = bounds[b], e = bounds[b + 1];
      if (e > s) segs.add(RouteSegment(pts.sublist(s, e + 1), _bands[b].level));
    }

    final allPts = [pts, altA, altB].expand((e) => e);
    var minLat = pts.first.latitude, maxLat = minLat;
    var minLng = pts.first.longitude, maxLng = minLng;
    for (final q in allPts) {
      minLat = math.min(minLat, q.latitude);
      maxLat = math.max(maxLat, q.latitude);
      minLng = math.min(minLng, q.longitude);
      maxLng = math.max(maxLng, q.longitude);
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final spanDeg = math.max(
      maxLat - minLat,
      (maxLng - minLng) * math.cos(center.latitude * math.pi / 180),
    );
    final double zoom = spanDeg <= 0
        ? 14
        : ((math.log(360 / spanDeg) / math.ln2) - 0.7).clamp(3.0, 16.0);

    return TrafficRoute._(
      points: pts,
      segments: segs,
      cumMeters: cum,
      totalMeters: total,
      center: center,
      fitZoom: zoom,
      alts: alts,
      mainMinutes: minutesFor(total, 1.0),
    );
  }

  /// Build from a ready polyline (Google Directions `overview_polyline` or an
  /// OSRM geometry) instead of the synthetic curve. Traffic bands are still
  /// assigned by fraction of length. Pass [alternatives] to keep real
  /// alternate routes for the map to draw.
  factory TrafficRoute.fromPath(
    List<LatLng> path, {
    int? minutes,
    List<RouteOption> alternatives = const [],
  }) {
    final pts = path.length >= 2
        ? List<LatLng>.of(path)
        : <LatLng>[
            if (path.isNotEmpty) path.first else const LatLng(0, 0),
            if (path.isNotEmpty) path.first else const LatLng(0, 0),
          ];

    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum[i - 1] + _dist(pts[i - 1], pts[i]));
    }
    final total = cum.last;

    final bounds = <int>[0];
    for (var b = 1; b < _bands.length; b++) {
      final m = _bands[b].frac * total;
      var idx = 0;
      while (idx < pts.length - 1 && cum[idx] < m) {
        idx++;
      }
      bounds.add(idx);
    }
    bounds.add(pts.length - 1);
    final segs = <RouteSegment>[];
    for (var b = 0; b < _bands.length; b++) {
      final s = bounds[b], e = bounds[b + 1];
      if (e > s) segs.add(RouteSegment(pts.sublist(s, e + 1), _bands[b].level));
    }

    var minLat = pts.first.latitude, maxLat = minLat;
    var minLng = pts.first.longitude, maxLng = minLng;
    for (final q in pts) {
      minLat = math.min(minLat, q.latitude);
      maxLat = math.max(maxLat, q.latitude);
      minLng = math.min(minLng, q.longitude);
      maxLng = math.max(maxLng, q.longitude);
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final spanDeg = math.max(
      maxLat - minLat,
      (maxLng - minLng) * math.cos(center.latitude * math.pi / 180),
    );
    final double zoom = spanDeg <= 0
        ? 14
        : ((math.log(360 / spanDeg) / math.ln2) - 0.7).clamp(3.0, 16.0);

    return TrafficRoute._(
      points: pts,
      segments: segs,
      cumMeters: cum,
      totalMeters: total,
      center: center,
      fitZoom: zoom,
      alts: alternatives,
      mainMinutes: minutes ?? math.max(1, (total / _metresPerMin).round()),
    );
  }

  TrafficLevel levelAt(double meters) {
    if (totalMeters <= 0) return TrafficLevel.free;
    final frac = (meters / totalMeters).clamp(0.0, 1.0);
    var lvl = _bands.first.level;
    for (final band in _bands) {
      if (frac >= band.frac) lvl = band.level;
    }
    return lvl;
  }

  /// Metre offset where the band covering [meters] ends — used to skip past a
  /// road block once the detour has been "taken".
  double bandEndMeters(double meters) {
    if (totalMeters <= 0) return 0;
    final frac = (meters / totalMeters).clamp(0.0, 1.0);
    for (var b = 0; b < _bands.length; b++) {
      final start = _bands[b].frac;
      final end = b + 1 < _bands.length ? _bands[b + 1].frac : 1.0;
      if (frac >= start && frac < end) return end * totalMeters;
    }
    return totalMeters;
  }

  /// Midpoint of the first stretch at [level], for dropping a warning pin.
  LatLng? midpointOf(TrafficLevel level) {
    for (final seg in segments) {
      if (seg.level == level && seg.points.isNotEmpty) {
        return seg.points[seg.points.length ~/ 2];
      }
    }
    return null;
  }

  /// Position and travel heading (radians, clockwise from north) at [meters]
  /// travelled from the origin.
  ({LatLng pos, double bearing}) sample(double meters) {
    if (points.length < 2 || totalMeters <= 0) {
      return (pos: points.first, bearing: 0);
    }
    final m = meters.clamp(0.0, totalMeters);
    var i = 1;
    while (i < cumMeters.length - 1 && cumMeters[i] < m) {
      i++;
    }
    final segLen = cumMeters[i] - cumMeters[i - 1];
    final f = segLen <= 0 ? 0.0 : (m - cumMeters[i - 1]) / segLen;
    final a = points[i - 1], b = points[i];
    final pos = LatLng(
      a.latitude + (b.latitude - a.latitude) * f,
      a.longitude + (b.longitude - a.longitude) * f,
    );
    return (pos: pos, bearing: _bearing(a, b));
  }

  static double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }
}
