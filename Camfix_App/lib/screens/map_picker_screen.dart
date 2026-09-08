import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_strings.dart';
import '../services/device_location.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

/// Full-screen map: pan / zoom, tap to drop a pin, confirm to return the
/// chosen [LatLng]. Uses OpenStreetMap tiles (no API key).
///
/// Push with an optional [LatLng] as `arguments` to start centred there.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _phnomPenh = LatLng(11.5564, 104.9282);

  final _map = MapController();
  LatLng? _picked;
  bool _argsRead = false;
  bool _locating = false;
  bool _mapReady = false;
  LatLng? _pendingCenter; // recentre here the moment the map is ready

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LatLng) {
      _picked = args;
    } else {
      // No start point supplied → drop the pin on the current user's real
      // location as soon as the screen opens, so "update address" begins
      // from where they actually are.
      _goToCurrentLocation(silentOnError: true);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Read the device GPS, drop the pin there and centre the map on it.
  /// [silentOnError] suppresses the error snack for the automatic call on
  /// open (the user can still tap the button to retry).
  Future<void> _goToCurrentLocation({bool silentOnError = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    final res = await getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (!res.ok) {
      if (!silentOnError) _snack(AppStrings.t(res.errorKey!));
      return;
    }
    final here = LatLng(res.position!.latitude, res.position!.longitude);
    setState(() => _picked = here);
    if (_mapReady) {
      _map.move(here, 16);
    } else {
      _pendingCenter = here; // onMapReady will consume this
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final center = _picked ?? _phnomPenh;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onMapReady: () {
                _mapReady = true;
                final c = _pendingCenter;
                if (c != null) {
                  _pendingCenter = null;
                  _map.move(c, 16);
                }
              },
              onTap: (_, latlng) => setState(() => _picked = latlng),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.camfix_app',
                maxZoom: 19,
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          size: 44, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
            ],
          ),

          // Header
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
                    _circle(Icons.arrow_back,
                        () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                          _picked != null
                              ? '${_picked!.latitude.toStringAsFixed(6)}, '
                                  '${_picked!.longitude.toStringAsFixed(6)}'
                              : _locating
                                  ? AppStrings.t('gettingLocation')
                                  : AppStrings.t('tapMapToPick'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13, color: p.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // "My location" button, sitting just above the confirm button
          Positioned(
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 84),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _locating ? null : () => _goToCurrentLocation(),
                  child: Container(
                    width: 48,
                    height: 48,
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
                    child: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location,
                            color: AppColors.primaryBlue, size: 22),
                  ),
                ),
              ),
            ),
          ),

          // Confirm
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PrimaryButton(
                  label: AppStrings.t('useThisLocation'),
                  background: AppColors.primaryBlue,
                  onPressed: _picked == null
                      ? null
                      : () => Navigator.of(context).pop(_picked),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) {
    final p = context.pal;
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
