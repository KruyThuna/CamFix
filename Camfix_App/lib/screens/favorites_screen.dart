import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/favorite.dart';
import '../services/api_client.dart';
import '../services/favorites_api.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

/// The customer's saved technicians (`Profile > Favorites`).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Favorite> _favorites = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await FavoritesApi.instance.list();
      if (mounted) setState(() => _favorites = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Favorite f) async {
    final previous = _favorites;
    setState(() => _favorites = _favorites.where((x) => x.id != f.id).toList());
    try {
      await FavoritesApi.instance.remove(f.technicianId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('removedFromFavorites'))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _favorites = previous);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.t('couldNotCall'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: Text(AppStrings.t('favorites'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(
                        child: Text(_error!,
                            style: TextStyle(color: p.textSecondary))),
                  ])
                : _favorites.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                          Icon(Icons.favorite_border_rounded,
                              size: 48, color: p.textSecondary),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(AppStrings.t('favoritesEmpty'),
                                style: TextStyle(
                                    color: p.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(AppStrings.t('favoritesEmptyHint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: p.textSecondary, fontSize: 12.5)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _card(p, _favorites[i]),
                      ),
      ),
    );
  }

  Widget _card(AppPalette p, Favorite f) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: p.surfaceAlt,
            backgroundImage: f.photoUrl == null
                ? null
                : NetworkImage('${ApiClient.instance.baseUrl}${f.photoUrl}'),
            child: f.photoUrl == null
                ? const Icon(Icons.person, color: AppColors.primaryBlue)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.technicianName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (f.category != null) categoryLabel(f.category!),
                    if (f.serviceArea != null) f.serviceArea!,
                  ].join(' · '),
                  style: TextStyle(color: p.textSecondary, fontSize: 12.5),
                ),
                if (f.ratingCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: Color(0xFFFFB300)),
                      const SizedBox(width: 3),
                      Text('${f.rating.toStringAsFixed(1)} (${f.ratingCount})',
                          style: TextStyle(
                              fontSize: 12, color: p.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _remove(f),
            icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE5484D)),
            tooltip: AppStrings.t('removedFromFavorites'),
          ),
          if (f.technicianPhone != null)
            IconButton(
              onPressed: () => _call(f.technicianPhone),
              icon: const Icon(Icons.call_outlined,
                  color: AppColors.primaryBlue),
            ),
        ],
      ),
    );
  }
}
