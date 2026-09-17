import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../services/current_user.dart';
import '../services/device_location.dart';
import '../services/technicians_api.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

/// Map fallback centre (Phnom Penh) for when device location isn't available
/// yet - only a starting viewport, never a claimed user position.
const _fallbackCentre = LatLng(11.5564, 104.9282);

/// "Nearby Technicians" live map: the current user's area plus every
/// approved technician's live position. Tap a marker (or a list row) to open
/// the provider. OpenStreetMap tiles, no API key.
///
/// Technicians come from `GET /api/technicians` - real accounts, not sample
/// data. A technician who has never gone online has no lat/lng
/// ([ServiceProvider.hasLocation] false); they still appear in the list
/// below (so "why don't I see them" isn't a mystery) but can't be pinned or
/// given a distance, since there's no real position to compute one from.
class TechniciansLiveScreen extends StatefulWidget {
  const TechniciansLiveScreen({super.key});

  @override
  State<TechniciansLiveScreen> createState() => _TechniciansLiveScreenState();
}

class _TechniciansLiveScreenState extends State<TechniciansLiveScreen> {
  List<ServiceProvider> _techs = const [];
  ServiceProvider? _selected;
  LatLng? _userPos;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    CurrentUser.instance.addListener(_onUser);
    CurrentUser.instance.refresh();
    _load();
  }

  @override
  void dispose() {
    CurrentUser.instance.removeListener(_onUser);
    super.dispose();
  }

  void _onUser() {
    if (mounted) setState(() {});
  }

  String get _userName {
    final n = CurrentUser.instance.value?.displayName.trim() ?? '';
    return n.isEmpty ? AppStrings.t('notSet') : n.split(RegExp(r'\s+')).first;
  }

  /// Reads GPS, fetches the real technician list, and computes each
  /// technician's distance from the user's actual position on-device (the
  /// backend doesn't do this itself). A failed GPS read still shows the
  /// list - only the distance figures and map pin are affected.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final fix = await getCurrentLocation();
    if (!mounted) return;
    if (fix.ok) {
      _userPos = LatLng(fix.position!.latitude, fix.position!.longitude);
    }

    try {
      final list = await TechniciansApi.instance.list();
      if (!mounted) return;
      setState(() {
        _techs = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _techs = const [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Real distance from the user to [t], or null when either position is
  /// unknown - never a placeholder number standing in for a real one.
  double? _distanceKm(ServiceProvider t) {
    final me = _userPos;
    if (me == null || !t.hasLocation) return null;
    return distanceKmBetween(me.latitude, me.longitude, t.latitude, t.longitude);
  }

  void _openProvider(ServiceProvider t) {
    Navigator.of(context).pushNamed('/provider', arguments: t);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _userPos ?? _fallbackCentre,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.camfix_app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  // Only drawn once GPS actually resolved - never claim a
                  // fake user position.
                  if (_userPos != null)
                    Marker(
                      point: _userPos!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                        ),
                      ),
                    ),
                  // Unlocated technicians show in the list below but can't be
                  // pinned - there is no real position to pin them at.
                  for (final t in _techs.where((t) => t.hasLocation))
                    Marker(
                      point: LatLng(t.latitude, t.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = t),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: _selected == t
                                    ? AppColors.primaryBlue
                                    : AppColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryBlue, width: 2),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.person,
                                  size: 18,
                                  color: _selected == t
                                      ? AppColors.white
                                      : AppColors.primaryBlue),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: t.available
                                      ? const Color(0xFF2ECC71)
                                      : AppColors.hintGrey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Header: back + current user greeting
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.t('nearbyTechnicians'),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary)),
                            Text('${AppStrings.t('nearYou')} · $_userName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: p.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom: selected card, or the full list
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _selected != null
                  ? _selectedCard(p, _selected!)
                  : _list(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedCard(AppPalette p, ServiceProvider t) {
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
        children: [
          _techRow(p, t),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openProvider(t),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(AppStrings.t('viewProfile')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(AppPalette p) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _techs.isEmpty
              ? _emptyState(p)
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _techs.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: p.border),
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => _openProvider(_techs[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: _techRow(p, _techs[i]),
                    ),
                  ),
                ),
    );
  }

  /// Shown when the fetch genuinely returned nobody (or failed) - better
  /// than an empty box, and it says why.
  Widget _emptyState(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 30, color: p.textSecondary),
          const SizedBox(height: 8),
          Text(
            _error ?? AppStrings.t('noTechniciansNearby'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _load, child: Text(AppStrings.t('retry'))),
        ],
      ),
    );
  }

  Widget _techRow(AppPalette p, ServiceProvider t) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: p.surfaceAlt,
          child: const Icon(Icons.person, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              Text(categoryLabel(t.category),
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Builder(builder: (_) {
              final km = _distanceKm(t);
              return Text(
                  km != null
                      ? '${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
                          '${AppStrings.t(AppSettings.instance.distanceUnitKey)} '
                          '${AppStrings.t('nearby')}'
                      : AppStrings.t('locationUnknown'),
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary));
            }),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  t.available ? Icons.verified : Icons.schedule,
                  size: 13,
                  color: t.available
                      ? AppColors.primaryBlue
                      : p.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  AppStrings.t(t.available ? 'available' : 'unavailable'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: t.available
                        ? AppColors.primaryBlue
                        : p.textSecondary,
                  ),
                ),
              ],
            ),
          ],
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
