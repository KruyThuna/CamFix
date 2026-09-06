import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import '../l10n/app_strings.dart';
import '../models/route_traffic.dart';
import '../models/tracking_info.dart';
import '../services/directions_api.dart';
import '../services/osrm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/google_map_view.dart';

/// Full-screen live map (mockup page 31). Once the customer's order is placed
/// the technician drives the route origin → destination: the line is coloured
/// by live traffic on each stretch (clear / slow / blocked / not-mapped), the
/// marker moves faster or slower to match, pauses at a road block and takes a
/// detour, and the card below reports what the technician is doing + the ETA.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  /// Real Google Maps is used when this is set *and* the platform key is
  /// configured (see GOOGLE_MAPS_SETUP.md); otherwise the OpenStreetMap view.
  static const String _mapsKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  bool get _useGoogle => _mapsKey.isNotEmpty;

  bool _booted = false;
  late final TrackingInfo _info;
  late TrafficRoute _route;
  final MapController _map = MapController();
  late final MapOptions _mapOptions;
  DirectionsResult? _directions; // Google path
  OsrmResult? _osrm; // OpenStreetMap path (real roads, keyless)

  Timer? _timer;
  double _traveled = 0; // metres from the origin
  double _blockWait = 0; // seconds still paused at a road block
  bool _arrived = false;
  DateTime _lastTick = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted) return;
    _booted = true;
    _info = ModalRoute.of(context)?.settings.arguments as TrackingInfo? ??
        TrackingInfo.sample;
    _route = TrafficRoute.build(_info.origin, _info.destination);
    _mapOptions = MapOptions(
      initialCameraFit: CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          ..._route.points,
          for (final a in _route.alts) ...a.points,
        ]),
        padding: const EdgeInsets.fromLTRB(36, 92, 36, 284),
      ),
      initialCenter: _route.center,
      initialZoom: _route.fitZoom,
      minZoom: 3,
      maxZoom: 18,
    );
    // A job already "in transit" starts a little way down the road.
    _traveled = _info.currentStep >= 1 ? _route.totalMeters * 0.06 : 0;
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 120), _tick);
    if (_useGoogle) {
      _loadDirections();
    } else {
      _loadOsrmRoute();
    }
  }

  /// Pull the real road route(s) from OSRM (keyless) so the technician follows
  /// the streets instead of a drawn line. Falls back to the synthetic curve if
  /// the call fails.
  Future<void> _loadOsrmRoute() async {
    final r = await OsrmApi.instance
        .route(origin: _info.origin, destination: _info.destination);
    if (r == null || !mounted) return;
    final alts = <RouteOption>[];
    for (var i = 1; i < r.routes.length && i <= 2; i++) {
      alts.add(RouteOption(r.routes[i].points, r.routes[i].meters,
          r.routes[i].minutes, i == 1 ? 0.5 : 0.62));
    }
    setState(() {
      _osrm = r;
      _route = TrafficRoute.fromPath(
        r.routes.first.points,
        minutes: r.routes.first.minutes,
        alternatives: alts,
      );
      if (_traveled > _route.totalMeters) _traveled = _route.totalMeters;
    });
    try {
      _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([
          ..._route.points,
          for (final a in _route.alts) ...a.points,
        ]),
        padding: const EdgeInsets.fromLTRB(36, 92, 36, 284),
      ));
    } catch (_) {/* map not ready yet */}
  }

  /// Ask Google for the real road route(s) + traffic-aware ETA. Mobile only
  /// (Google blocks the Directions call from a browser); web keeps the drawn
  /// route on top of the real Google tiles + traffic layer.
  Future<void> _loadDirections() async {
    final d = await DirectionsApi.instance.route(
      origin: gm.LatLng(_info.origin.latitude, _info.origin.longitude),
      destination:
          gm.LatLng(_info.destination.latitude, _info.destination.longitude),
    );
    if (!mounted) return;
    if (d == null) {
      // No Directions (e.g. web/CORS) — still put the technician on real roads.
      await _loadOsrmRoute();
      return;
    }
    setState(() {
      _directions = d;
      _route = TrafficRoute.fromPath(
        d.routes.first.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        minutes: (d.routes.first.durationSeconds / 60).round(),
      );
      if (_traveled > _route.totalMeters) _traveled = _route.totalMeters;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer _) {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;
    if (_arrived || !mounted) return;
    setState(() {
      final lvl = _route.levelAt(_traveled);
      if (lvl == TrafficLevel.blocked && _blockWait <= 0 && _traveled > 0) {
        _blockWait = 4; // stop, then detour
      }
      if (_blockWait > 0) {
        _blockWait -= dt;
        if (_blockWait <= 0) _traveled = _route.bandEndMeters(_traveled);
        return;
      }
      _traveled += lvl.speed * dt;
      if (_traveled >= _route.totalMeters) {
        _traveled = _route.totalMeters;
        _arrived = true;
        _timer?.cancel();
      }
    });
  }

  String _statusKey() {
    if (_arrived) return 'statusArrived';
    if (_blockWait > 0) return 'statusBlocked';
    return switch (_route.levelAt(_traveled)) {
      TrafficLevel.free => 'statusMovingFast',
      TrafficLevel.moderate => 'statusSteady',
      TrafficLevel.heavy => 'statusSlow',
      TrafficLevel.blocked => 'statusBlocked',
      TrafficLevel.unknown => 'statusNoData',
    };
  }

  Color _statusColor() {
    if (_arrived) return AppColors.primaryBlue;
    if (_blockWait > 0) return TrafficLevel.blocked.color;
    return _route.levelAt(_traveled).color;
  }

  String _eta() {
    if (_directions != null) {
      final r = _directions!.routes.first;
      return '${r.durationText} · ${r.distanceText}';
    }
    if (_osrm != null) return _routeLabel(_route.mainMinutes, _route.mainKm);
    if (_arrived) return AppStrings.t('arrived');
    var secs = _blockWait;
    var m = _traveled;
    const step = 25.0;
    while (m < _route.totalMeters) {
      final lvl = _route.levelAt(m);
      final spd = lvl == TrafficLevel.blocked ? 8.0 : lvl.speed;
      secs += step / spd;
      m += step;
    }
    final mins = secs ~/ 60;
    final rem = (secs % 60).round();
    return mins > 0 ? '~$mins min $rem s' : '~$rem s';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (!_booted) return const SizedBox.shrink();
    final here = _route.sample(_traveled);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      body: Stack(
        children: [
          if (_useGoogle)
            GoogleMapView(
              route: _route,
              directions: _directions,
              technician: here.pos,
              technicianBearingDeg: here.bearing * 180 / math.pi,
            )
          else
            _osmMap(here),
          _backButton(p),
          if (!_useGoogle) _legend(p),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 4),
                    child: Text(
                      _useGoogle
                          ? 'Map data © Google'
                          : '© OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  if (!_useGoogle)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 10),
                        child: Column(
                          children: [
                            _zoomBtn(p, Icons.remove, () => _zoomBy(-1)),
                            const SizedBox(height: 8),
                            _zoomBtn(p, Icons.add, () => _zoomBy(1)),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _card(p),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _osmMap(({LatLng pos, double bearing}) here) => FlutterMap(
        mapController: _map,
        options: _mapOptions,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.camfix_app',
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
          PolylineLayer(
            polylines: [
              for (final alt in _route.alts) ...[
                Polyline(
                  points: alt.points,
                  strokeWidth: 9,
                  color: const Color(0xFFB0BBD4),
                ),
                Polyline(
                  points: alt.points,
                  strokeWidth: 5,
                  color: const Color(0xFF8A96B4),
                ),
              ],
              Polyline(
                points: _route.points,
                strokeWidth: 11,
                color: const Color(0xFF1A63D8),
              ),
              for (final seg in _route.segments)
                Polyline(
                  points: seg.points,
                  strokeWidth: seg.level == TrafficLevel.blocked ? 7 : 6,
                  color: seg.level.color,
                ),
            ],
          ),
          MarkerLayer(
            markers: [
              for (final alt in _route.alts)
                Marker(
                  point: alt.labelAnchor,
                  width: 104,
                  height: 28,
                  child: _routeBubble(
                      _routeLabel(alt.minutes, alt.km), faint: true),
                ),
              Marker(
                point: _route.mainLabelAnchor,
                width: 108,
                height: 28,
                child: _routeBubble(
                    _routeLabel(_route.mainMinutes, _route.mainKm),
                    faint: false),
              ),
              _originDot(_route.points.first),
              _destPin(_route.points.last),
              if (_route.midpointOf(TrafficLevel.blocked) case final b?)
                _pin(b, TrafficLevel.blocked.color, Icons.block),
              if (_route.midpointOf(TrafficLevel.unknown) case final u?)
                _pin(u, TrafficLevel.unknown.color, Icons.help_outline),
              Marker(
                point: here.pos,
                width: 46,
                height: 46,
                rotate: true,
                child: _technician(here.bearing),
              ),
            ],
          ),
        ],
      );

  void _zoomBy(double d) {
    final z = (_map.camera.zoom + d).clamp(3.0, 18.0);
    _map.move(_map.camera.center, z);
  }

  Widget _zoomBtn(AppPalette p, IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: p.shadow, blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: p.textPrimary, size: 20),
        ),
      );

  Widget _technician(double bearing) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4C8DFF), width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
          ],
        ),
        padding: const EdgeInsets.all(7),
        child: Transform.rotate(
          angle: bearing,
          child: const Icon(Icons.navigation,
              color: AppColors.primaryBlue, size: 18),
        ),
      );

  /// Pickup / current position — Google-style blue location dot.
  Marker _originDot(LatLng at) => Marker(
        point: at,
        width: 30,
        height: 30,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C8DFF).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C8DFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
              ),
            ],
          ),
        ),
      );

  /// Destination — Google-style red teardrop pin (tip on the point).
  Marker _destPin(LatLng at) => Marker(
        point: at,
        width: 40,
        height: 44,
        alignment: Alignment.topCenter,
        child: const Icon(
          Icons.location_on,
          color: Color(0xFFEA4335),
          size: 40,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
      );

  String _routeLabel(int minutes, double km) =>
      '$minutes ${AppStrings.t('minShort')} · '
      '${km.toStringAsFixed(1)} ${AppStrings.t('kmShort')}';

  /// Google-style "X min · Y km" pill sitting on a route line.
  Widget _routeBubble(String text, {required bool faint}) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: faint ? AppColors.white : const Color(0xFF1A63D8),
            borderRadius: BorderRadius.circular(13),
            border: faint
                ? Border.all(color: const Color(0xFFB0BBD4))
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1)),
            ],
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: faint ? const Color(0xFF3C4043) : AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  Marker _pin(LatLng at, Color color, IconData icon) => Marker(
        point: at,
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          child: Icon(icon, color: AppColors.white, size: 16),
        ),
      );

  Widget _backButton(AppPalette p) => Positioned(
        top: 0,
        left: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: p.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: p.textPrimary, size: 20),
              ),
            ),
          ),
        ),
      );

  Widget _legend(AppPalette p) => Positioned(
        top: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: p.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t('trafficTitle'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary)),
                  const SizedBox(height: 6),
                  for (final lvl in TrafficLevel.values)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 4,
                            decoration: BoxDecoration(
                              color: lvl.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(AppStrings.t(lvl.labelKey),
                              style: TextStyle(
                                  fontSize: 11, color: p.textPrimary)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _card(AppPalette p) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(AppStrings.t('trackingDetails'),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
                const Spacer(),
                Text(AppStrings.t('etaLabel'),
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
                const SizedBox(width: 6),
                Text(_eta(),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: _statusColor(), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppStrings.t(_statusKey()),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _leg(
                        p, AppStrings.t('fromLabel'), _info.originName)),
                Icon(Icons.arrow_forward, size: 16, color: p.textSecondary),
                Expanded(
                    child: _leg(p, AppStrings.t('destination'),
                        _info.destinationName,
                        alignEnd: true)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkButton,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.white,
                    child: Icon(Icons.person,
                        color: AppColors.darkButton, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_info.technicianName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white)),
                        Text(AppStrings.t('technicianLabel'),
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.white
                                    .withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  _round(Icons.chat_bubble_outline_rounded,
                      () => Navigator.of(context).pushNamed('/chat')),
                  const SizedBox(width: 8),
                  _round(Icons.call_outlined, () {}),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _leg(AppPalette p, String label, String value,
      {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: p.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary)),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryBlue),
        ),
      );
}
