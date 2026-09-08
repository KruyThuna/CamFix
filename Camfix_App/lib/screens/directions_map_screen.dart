import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/live_technician.dart';
import '../models/service_provider.dart';
import '../services/osrm_api.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

/// Full-screen, in-app directions to a technician's shop. Draws the real
/// road route (keyless OSRM) from the user's area to the provider's pin, so
/// the customer can see where to go to check the repair without leaving the
/// app. A "Open in Maps app" button hands off to Google Maps for turn-by-turn.
class DirectionsMapScreen extends StatefulWidget {
  const DirectionsMapScreen({super.key});

  @override
  State<DirectionsMapScreen> createState() => _DirectionsMapScreenState();
}

class _DirectionsMapScreenState extends State<DirectionsMapScreen> {
  final MapController _map = MapController();

  bool _booted = false;
  late final ServiceProvider _provider;
  late final LatLng _origin;
  late final LatLng _dest;
  late final MapOptions _mapOptions;

  List<LatLng> _route = const [];
  double _km = 0;
  int _min = 0;
  bool _loading = true;
  bool _directLine = false; // OSRM failed → straight line fallback

  static const _blue = AppColors.primaryBlue;
  static const _amber = Color(0xFFF6A609);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted) return;
    _booted = true;

    _provider =
        ModalRoute.of(context)?.settings.arguments as ServiceProvider? ??
            const ServiceProvider(
              name: 'Technician',
              category: 'Service',
              location: 'Phnom Penh',
              rating: 4.5,
            );
    _origin = LiveTechnician.userPos;
    _dest = LatLng(_provider.latitude, _provider.longitude);
    _mapOptions = MapOptions(
      initialCameraFit: CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([_origin, _dest]),
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 240),
      ),
      initialCenter: _dest,
      initialZoom: 13,
      minZoom: 3,
      maxZoom: 18,
    );
    _load();
  }

  Future<void> _load() async {
    // The first frame renders immediately on the endpoint-fit camera; this
    // fills in the real road line when (if) OSRM answers.
    final osrm = await _fetchRoute();
    if (!mounted) return;
    if (osrm == null) {
      final straight =
          const Distance().as(LengthUnit.Kilometer, _origin, _dest).toDouble();
      setState(() {
        _route = [_origin, _dest];
        _km = straight;
        _min = (straight / 0.5).round().clamp(1, 100000); // ~30 km/h city guess
        _directLine = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _route = osrm.$1;
      _km = osrm.$2;
      _min = osrm.$3;
      _loading = false;
    });
    try {
      _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_route),
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 240),
      ));
    } catch (_) {/* map not ready yet — initialCameraFit already covers it */}
  }

  /// (points, km, minutes) for the best OSRM route, or null on any failure.
  Future<(List<LatLng>, double, int)?> _fetchRoute() async {
    try {
      final r =
          await OsrmApi.instance.route(origin: _origin, destination: _dest);
      if (r == null || r.routes.isEmpty) return null;
      final best = r.routes.first;
      if (best.points.length < 2) return null;
      return (best.points, best.km, best.minutes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openInMapsApp() async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&destination=${_dest.latitude},${_dest.longitude}'
        '&travelmode=driving');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack(AppStrings.t('couldNotOpenMaps'));
    } catch (_) {
      if (mounted) _snack(AppStrings.t('couldNotOpenMaps'));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: _mapOptions,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.camfix_app',
                maxZoom: 19,
              ),
              if (_route.length >= 2)
                PolylineLayer(
                  polylines: [
                    // Soft outline under the route for contrast on busy tiles.
                    Polyline(
                      points: _route,
                      strokeWidth: 9,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                    Polyline(
                      points: _route,
                      strokeWidth: 5,
                      color: _directLine ? _blue.withValues(alpha: 0.5) : _blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _origin,
                    width: 26,
                    height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                    ),
                  ),
                  Marker(
                    point: _dest,
                    width: 44,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: _shopMarker(),
                  ),
                ],
              ),
            ],
          ),

          // Back button + title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    _circle(p, Icons.arrow_back,
                        () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
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
                      child: Text(
                        AppStrings.t('directionsTitle'),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary),
                      ),
                    ),
                    if (_loading) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom info + hand-off card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _infoCard(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(AppPalette p) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: _amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_provider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary)),
                    Text(
                      '${categoryLabel(_provider.category)} · ${_provider.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.directions_car_filled_rounded,
                  size: 16, color: p.textSecondary),
              const SizedBox(width: 6),
              Text(
                _loading
                    ? '…'
                    : '${_km.toStringAsFixed(1)} ${AppStrings.t('kmShort')}'
                        '   ·   ~$_min ${AppStrings.t('minShort')}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary),
              ),
            ],
          ),
          if (_directLine) ...[
            const SizedBox(height: 6),
            Text(
              AppStrings.t('routeUnavailable'),
              style: TextStyle(fontSize: 11.5, color: p.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInMapsApp,
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: Text(AppStrings.t('openInMapsApp')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: AppColors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _amber,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2.5),
          ),
          child: const Icon(Icons.storefront_rounded,
              color: AppColors.white, size: 18),
        ),
        Transform.translate(
          offset: const Offset(0, -5),
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(width: 11, height: 11, color: _amber),
          ),
        ),
      ],
    );
  }

  Widget _circle(AppPalette p, IconData icon, VoidCallback onTap) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: p.textPrimary, size: 20),
      ),
    );
  }
}
