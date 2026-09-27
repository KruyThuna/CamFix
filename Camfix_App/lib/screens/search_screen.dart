import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../services/api_client.dart';
import '../services/search_history_store.dart';
import '../services/service_prices_api.dart';
import '../services/technicians_api.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

/// Dedicated search screen (mockup pages 53-54): a real "Recently searched"
/// list (this device's own past queries, stored locally - not fabricated),
/// real service-category shortcuts with real starting prices, and live
/// results filtered from the real technician list. There's no per-item
/// service catalog ("Ceiling Fan Installation", "Smart Switch Board Setup"
/// as individually rated/priced things) anywhere in the backend, so results
/// are technicians, same as the Services tab - not invented listings.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  bool _loading = true;
  List<ServiceProvider> _providers = const [];
  List<ServicePriceInfo> _prices = const [];

  static const _categories = [
    'Air Conditioner',
    'Electrical',
    'Appliance Repair',
    'Motorcycle',
    'Car',
    'Water network',
  ];

  static const _categoryIcons = {
    'Air Conditioner': Icons.ac_unit_rounded,
    'Electrical': Icons.electrical_services_rounded,
    'Appliance Repair': Icons.handyman_rounded,
    'Motorcycle': Icons.two_wheeler_rounded,
    'Car': Icons.directions_car_filled_rounded,
    'Water network': Icons.plumbing_rounded,
  };

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    SearchHistoryStore.instance.addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    SearchHistoryStore.instance.removeListener(_onChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        TechniciansApi.instance.list(),
        ServicePricesApi.instance.list(),
      ]);
      if (!mounted) return;
      setState(() {
        _providers = results[0] as List<ServiceProvider>;
        _prices = results[1] as List<ServicePriceInfo>;
      });
    } catch (_) {
      // Search still works against an empty result set while offline.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _priceFor(String category) {
    for (final price in _prices) {
      if (price.categoryName == category) return price.startingPrice;
    }
    return null;
  }

  List<ServiceProvider> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _providers
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            categoryLabel(p.category).toLowerCase().contains(q) ||
            p.about.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  void _runSearch(String text) {
    setState(() {
      _query = text;
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    });
    if (text.trim().isNotEmpty) {
      SearchHistoryStore.instance.add(text.trim());
    }
  }

  void _openCategory(String category) {
    Navigator.of(context).pushNamed('/services', arguments: category);
  }

  void _openProvider(ServiceProvider p) {
    _runSearch(_controller.text);
    Navigator.of(context).pushNamed('/provider', arguments: p);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final showResults = _query.trim().isNotEmpty;
    final history = SearchHistoryStore.instance.items;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
            child: Column(
              children: [
                _buildSearchBar(p),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : showResults
                          ? _buildResults(p)
                          : _buildIdle(p, history),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: p.textPrimary),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: _runSearch,
                style: TextStyle(fontSize: 14, color: p.textPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.t('searchForService'),
                  hintStyle: TextStyle(fontSize: 13, color: p.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: p.textSecondary),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _runSearch(''),
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle(AppPalette p, List<String> history) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.t('recentlySearched'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              GestureDetector(
                onTap: () => SearchHistoryStore.instance.clear(),
                child: Text(AppStrings.t('clearAll'),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final q in history)
            InkWell(
              onTap: () => _runSearch(q),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 18, color: p.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(q,
                          style:
                              TextStyle(fontSize: 13.5, color: p.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
        Text(AppStrings.t('browseByCategory'),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.textPrimary)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, i) {
            final c = _categories[i];
            final price = _priceFor(c);
            return InkWell(
              onTap: () => _openCategory(c),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_categoryIcons[c],
                        color: AppColors.primaryBlue, size: 22),
                    const SizedBox(height: 6),
                    Text(categoryLabel(c),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary)),
                    if (price != null) ...[
                      const SizedBox(height: 2),
                      Text('From \$${price.toStringAsFixed(0)}',
                          style:
                              TextStyle(fontSize: 10, color: p.textSecondary)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResults(AppPalette p) {
    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: p.textSecondary),
              const SizedBox(height: 10),
              Text(AppStrings.t('noSearchResults'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textSecondary)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _resultCard(p, results[i]),
    );
  }

  Widget _resultCard(AppPalette p, ServiceProvider provider) {
    final price = _priceFor(provider.category);
    final hasPhoto = provider.photoUrl?.isNotEmpty ?? false;
    return InkWell(
      onTap: () => _openProvider(provider),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
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
              backgroundImage: hasPhoto
                  ? NetworkImage(
                      '${ApiClient.instance.baseUrl}${provider.photoUrl}')
                  : null,
              child: hasPhoto
                  ? null
                  : const Icon(Icons.person, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: p.textPrimary)),
                  Text(categoryLabel(provider.category),
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(provider.rating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary)),
                      Text(' (${provider.ratingCount})',
                          style:
                              TextStyle(fontSize: 11, color: p.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            if (price != null)
              Text('\$${price.toStringAsFixed(0)}+',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryBlue)),
          ],
        ),
      ),
    );
  }
}
