import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../l10n/app_strings.dart';
import '../models/live_technician.dart';
import '../models/service_provider.dart';
import '../services/current_user.dart';
import '../theme/app_theme.dart';

/// "Nearby Technicians" live map: the current user's area plus every
/// technician's live position. Tap a marker (or a list row) to open the
/// provider. OpenStreetMap tiles, no API key.
class TechniciansLiveScreen extends StatefulWidget {
  const TechniciansLiveScreen({super.key});

  @override
  State<TechniciansLiveScreen> createState() => _TechniciansLiveScreenState();
}

class _TechniciansLiveScreenState extends State<TechniciansLiveScreen> {
  final _techs = LiveTechnician.sample;
  LiveTechnician? _selected;

  @override
  void initState() {
    super.initState();
    CurrentUser.instance.addListener(_onUser);
    CurrentUser.instance.refresh();
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

  void _openProvider(LiveTechnician t) {
    Navigator.of(context).pushNamed(
      '/provider',
      arguments: ServiceProvider(
        name: t.name,
        category: t.category,
        location: 'Phnom Penh',
        rating: 4.5,
        distanceKm: t.distanceKm,
        available: t.available,
        latitude: t.pos.latitude,
        longitude: t.pos.longitude,
      ),
    );
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
              initialCenter: LiveTechnician.userPos,
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
                  Marker(
                    point: LiveTechnician.userPos,
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
                  for (final t in _techs)
                    Marker(
                      point: t.pos,
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

  Widget _selectedCard(AppPalette p, LiveTechnician t) {
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
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _techs.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: p.border),
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

  Widget _techRow(AppPalette p, LiveTechnician t) {
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
              Text(t.category,
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${t.distanceKm}km ${AppStrings.t('nearby')}',
                style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
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
