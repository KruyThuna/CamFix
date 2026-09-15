import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_strings.dart';
import '../services/device_location.dart';
import '../services/geocoding_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

/// Full-screen map: search a place by name, use the device's current
/// location, or tap to drop a pin - then confirm to return the chosen
/// [LatLng]. Uses OpenStreetMap tiles + Nominatim search (no API key).
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
  final _searchController = TextEditingController();
  LatLng? _picked;
  bool _argsRead = false;
  bool _locating = false;
  bool _resolvingAddress = false;
  bool _mapReady = false;
  LatLng? _pendingCenter; // recentre here the moment the map is ready

  List<GeocodeResult> _results = const [];
  bool _searching = false;
  bool _suppressNextChange = false;
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LatLng) {
      _picked = args;
      unawaited(_resolveAddress(args));
    } else {
      // No start point supplied → drop the pin on the current user's real
      // location as soon as the screen opens, so "update address" begins
      // from where they actually are.
      _goToCurrentLocation(silentOnError: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
    _recenter(here);
    unawaited(_resolveAddress(here));
  }

  void _recenter(LatLng point) {
    if (_mapReady) {
      _map.move(point, 16);
    } else {
      _pendingCenter = point; // onMapReady will consume this
    }
  }

  /// Coordinates → a readable label shown in the search box, so the user
  /// sees a real address instead of raw numbers once a point is picked.
  Future<void> _resolveAddress(LatLng point) async {
    setState(() => _resolvingAddress = true);
    final label = await GeocodingApi.instance.reverse(point.latitude, point.longitude);
    if (!mounted || _picked != point) return;
    setState(() => _resolvingAddress = false);
    _suppressNextChange = true;
    _searchController.text = label ??
        '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  void _onSearchChanged(String value) {
    if (_suppressNextChange) {
      _suppressNextChange = false;
      return;
    }
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(q));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    final results = await GeocodingApi.instance.search(query);
    if (!mounted || _searchController.text.trim() != query) return;
    setState(() {
      _searching = false;
      _results = results;
    });
  }

  void _selectResult(GeocodeResult r) {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    final point = LatLng(r.lat, r.lng);
    _suppressNextChange = true;
    _searchController.text = r.displayName;
    setState(() {
      _picked = point;
      _results = const [];
    });
    _recenter(point);
  }

  void _onMapTap(LatLng point) {
    FocusScope.of(context).unfocus();
    setState(() {
      _picked = point;
      _results = const [];
    });
    unawaited(_resolveAddress(point));
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
              onTap: (_, latlng) => _onMapTap(latlng),
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

          // Header: back arrow + search field, with a results dropdown.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _circle(Icons.arrow_back,
                            () => Navigator.of(context).maybePop()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
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
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    size: 18, color: p.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    style: TextStyle(
                                        fontSize: 13, color: p.textPrimary),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: _locating
                                          ? AppStrings.t('gettingLocation')
                                          : AppStrings.t('searchLocationHint'),
                                      hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: p.textSecondary),
                                    ),
                                  ),
                                ),
                                if (_searching || _resolvingAddress)
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: p.textSecondary),
                                    ),
                                  )
                                else if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        size: 16, color: p.textSecondary),
                                    onPressed: () {
                                      _debounce?.cancel();
                                      _searchController.clear();
                                      setState(() => _results = const []);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_results.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8, left: 54),
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: p.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: p.border),
                          itemBuilder: (context, i) {
                            final r = _results[i];
                            return InkWell(
                              onTap: () => _selectResult(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.place_outlined,
                                        size: 16, color: p.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        r.displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: p.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
