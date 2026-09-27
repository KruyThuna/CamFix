import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../services/api_client.dart';
import '../services/device_location.dart';
import '../services/technicians_api.dart';
import '../services/service_prices_api.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

/// Maps an internal category name to its localised label. `'All'` is a
/// pseudo-category (browse every technician, unfiltered) rather than a real
/// service type.
String categoryLabel(String category) {
  const keys = {
    'All': 'svcAllServices',
    'Air Conditioner': 'svcAirConditioner',
    'Electrical': 'svcElectrical',
    'Appliance Repair': 'svcApplianceRepair',
    'Motorcycle': 'svcMotorcycle',
    'Car': 'svcCar',
    'Water network': 'svcWaterNetwork',
  };
  final key = keys[category];
  return key == null ? category : AppStrings.t(key);
}

/// Maps an internal category name to its short description, shown on the
/// Services screen under the category chips.
String categoryDescription(String category) {
  const keys = {
    'All': 'svcAllServicesDesc',
    'Air Conditioner': 'svcAirConditionerDesc',
    'Electrical': 'svcElectricalDesc',
    'Appliance Repair': 'svcApplianceRepairDesc',
    'Motorcycle': 'svcMotorcycleDesc',
    'Car': 'svcCarDesc',
    'Water network': 'svcWaterNetworkDesc',
  };
  final key = keys[category];
  return key == null ? '' : AppStrings.t(key);
}

/// "Services" screen â€” pick a category chip, then browse the providers who
/// offer that service. Matches mockup pages 14â€“15 (Air Conditioner / Car).
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const _blue = Color(0xff285ff4);
  static const _categories = [
    'All',
    'Air Conditioner',
    'Electrical',
    'Appliance Repair',
    'Motorcycle',
    'Car',
    'Water network'
  ];
  final _searchController = TextEditingController();
  final _resultsKey = GlobalKey();
  String _category = 'All';
  String _query = '';
  String _sort = 'Top rated';
  bool _availableOnly = false;
  bool _ascending = false;
  bool _appliedRouteCategory = false;
  bool _loading = true;
  String? _error;
  List<ServiceProvider> _providers = const [];
  List<ServicePriceInfo> _prices = const [];
  MainShellController? _shell;

  /// The customer's real GPS fix, for the "X Km nearby" badge - best-effort,
  /// same fallback (badge just doesn't show) used by the dashboard's
  /// "Available Near You" list.
  double? _userLat;
  double? _userLng;

  /// Real distance from the user to [t], or null when either position is
  /// unknown - never a fabricated/default number.
  double? _distanceKm(ServiceProvider t) {
    if (_userLat == null || _userLng == null || !t.hasLocation) return null;
    return distanceKmBetween(_userLat!, _userLng!, t.latitude, t.longitude);
  }

  List<ServiceProvider> get _visibleProviders {
    final query = _query.trim().toLowerCase();
    final result = _providers
        .where((p) =>
            (_category == 'All' || p.category == _category) &&
            (!_availableOnly || p.available) &&
            (_sort != 'Featured' ||
                p.bannerUrl != null ||
                (p.bannerTitle?.isNotEmpty ?? false)) &&
            (query.isEmpty ||
                '${p.name} ${p.about} ${p.bannerTitle ?? ''} ${p.location}'
                    .toLowerCase()
                    .contains(query)))
        .toList();
    result.sort((a, b) => _sort == 'Recommend'
        ? b.ratingCount.compareTo(a.ratingCount)
        : b.rating.compareTo(a.rating));
    return _ascending ? result.reversed.toList() : result;
  }

  /// Starting price for [category] - looked up per-provider (not the
  /// screen-level [_category]) so it stays correct while browsing "All".
  double? _priceFor(String category) {
    for (final price in _prices) {
      if (price.categoryName == category) return price.startingPrice;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
    getCurrentLocation().then((fix) {
      if (mounted && fix.ok) {
        setState(() {
          _userLat = fix.position!.latitude;
          _userLng = fix.position!.longitude;
        });
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // A pricing outage must not hide technicians who are still bookable.
    final prices = ServicePricesApi.instance
        .list(forceRefresh: true)
        .catchError((_) => <ServicePriceInfo>[]);
    try {
      final providers = await TechniciansApi.instance.list();
      final catalog = await prices;
      if (mounted) {
        setState(() {
          _providers = providers;
          _prices = catalog;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Unable to load technicians. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_appliedRouteCategory) {
      _appliedRouteCategory = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && _categories.contains(arg)) _category = arg;
    }
    final shell = MainShell.of(context);
    if (shell != _shell) {
      _shell?.pendingCategory.removeListener(_applyPendingCategory);
      _shell = shell;
      _shell?.pendingCategory.addListener(_applyPendingCategory);
      _applyPendingCategory();
    }
  }

  void _applyPendingCategory() {
    final category = _shell?.pendingCategory.value;
    if (category != null && _categories.contains(category)) {
      setState(() => _category = category);
      _shell?.pendingCategory.value = null;
    }
  }

  @override
  void dispose() {
    _shell?.pendingCategory.removeListener(_applyPendingCategory);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final providers = _visibleProviders;
    return Scaffold(
        backgroundColor: p.surface,
        body: SafeArea(
          bottom: false,
          child: Center(
              child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
            child: Column(children: [
              _buildHeader(),
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 10, 16,
                            110 + MediaQuery.paddingOf(context).bottom),
                        children: [
                          _buildBanner(),
                          const SizedBox(height: 13),
                          _buildSearchField(),
                          const SizedBox(height: 15),
                          _buildFilters(),
                          const SizedBox(height: 18),
                          SizedBox(key: _resultsKey),
                          if (_loading)
                            const Padding(
                                padding: EdgeInsets.all(32),
                                child:
                                    Center(child: CircularProgressIndicator()))
                          else if (_error != null)
                            _buildStatus(Icons.cloud_off_outlined, _error!,
                                retry: true)
                          else if (providers.isEmpty)
                            _buildStatus(
                                Icons.search_off,
                                _query.isEmpty
                                    ? AppStrings.t('noProvidersInCategory')
                                    : AppStrings.t('noProvidersMatch'))
                          else
                            ...providers.map((provider) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _buildProviderCard(provider))),
                          const SizedBox(height: 10),
                          _buildHelp(),
                        ],
                      ))),
            ]),
          )),
        ));
  }

  Widget _buildHeader() {
    final p = context.pal;
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
        child: Row(children: [
          IconButton(
              tooltip: 'Back',
              onPressed: () {
                final shell = MainShell.of(context);
                if (shell != null) {
                  shell.goToTab(0);
                } else {
                  Navigator.maybePop(context);
                }
              },
              icon: Icon(Icons.arrow_back, size: 18, color: p.textPrimary)),
          Expanded(
              child: PopupMenuButton<String>(
                  tooltip: 'Choose service category',
                  onSelected: (value) => setState(() => _category = value),
                  itemBuilder: (_) => _categories
                      .map((c) => PopupMenuItem(
                          value: c, child: Text(categoryLabel(c))))
                      .toList(),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(categoryLabel(_category),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary))))),
          _headerAction('Favorites', Icons.favorite, Colors.red, '/favorites'),
          _headerAction('Notifications', Icons.notifications_outlined, _blue,
              '/notifications'),
          _headerAction('Profile', Icons.person, _blue, '/profile'),
        ]));
  }

  Widget _headerAction(
          String label, IconData icon, Color color, String route) =>
      SizedBox(
          width: 36,
          child: IconButton(
              tooltip: label,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pushNamed(context, route),
              icon: Icon(icon, color: color, size: 22)));

  static const _categoryAccents = {
    'All': AppColors.primaryBlue,
    'Air Conditioner': Color(0xff2f6bff),
    'Electrical': Color(0xffb8860b),
    'Appliance Repair': Color(0xff7c3aed),
    'Motorcycle': Color(0xffea580c),
    'Car': Color(0xff0f766e),
    'Water network': Color(0xff0e9488),
  };

  static const _categoryIcons = {
    'All': Icons.apps_rounded,
    'Air Conditioner': Icons.ac_unit_rounded,
    'Electrical': Icons.electrical_services_rounded,
    'Appliance Repair': Icons.handyman_rounded,
    'Motorcycle': Icons.two_wheeler_rounded,
    'Car': Icons.directions_car_filled_rounded,
    'Water network': Icons.plumbing_rounded,
  };

  // Thematic tag per category — a description, not a factual claim (unlike
  // a discount percentage or a verification stat, which would need real
  // backend data behind them).
  static const _categoryTags = {
    'All': 'ALL SERVICES',
    'Air Conditioner': 'COOLING CARE',
    'Electrical': 'HOME SAFETY',
    'Appliance Repair': 'QUICK FIX',
    'Motorcycle': 'ROADSIDE READY',
    'Car': 'FULL SERVICE',
    'Water network': 'LEAK FREE',
  };

  /// Category banner — matches the mockup's structure (two badges, bold
  /// headline, description, icon box) with real label/description text and
  /// no fabricated discount, coupon, or verification-stat claim.
  Widget _buildBanner() {
    final accent = _categoryAccents[_category] ?? AppColors.primaryBlue;
    final icon = _categoryIcons[_category] ?? Icons.home_repair_service;
    final tag = _categoryTags[_category] ?? 'HOME SERVICE';
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: .78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _bannerBadge('✓ VERIFIED PROS', filled: false),
            _bannerBadge(tag, filled: true, accent: accent),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(categoryLabel(_category),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1)),
                  const SizedBox(height: 6),
                  Text(categoryDescription(_category),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .92),
                          fontSize: 10.5,
                          height: 1.45)),
                ])),
            const SizedBox(width: 10),
            Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(height: 6),
                  const Text('EXPERT CARE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          letterSpacing: .5,
                          fontWeight: FontWeight.w800)),
                ])),
          ]),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: .2), height: 1),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            const Expanded(
                child: Text('Find your local specialist',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600))),
            const SizedBox(width: 6),
            FilledButton(
                onPressed: () {
                  final target = _resultsKey.currentContext;
                  if (target != null) {
                    Scrollable.ensureVisible(target,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut);
                  }
                },
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accent,
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact),
                child: const Text('Book now',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w800))),
          ]),
        ]));
  }

  Widget _bannerBadge(String text, {required bool filled, Color? accent}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
              color:
                  filled ? Colors.white : Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
              border: filled
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: .4))),
          child: Text(text,
              style: TextStyle(
                  color:
                      filled ? (accent ?? AppColors.primaryBlue) : Colors.white,
                  fontSize: 8.5,
                  letterSpacing: .3,
                  fontWeight: FontWeight.w800)));

  Widget _buildSearchField() {
    final p = context.pal;
    return TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        style: TextStyle(fontSize: 12, color: p.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: _category == 'Electrical'
              ? 'Search electrical repairs, rewiring...'
              : AppStrings.t('searchForService'),
          hintStyle: TextStyle(fontSize: 10, color: p.textSecondary),
          prefixIcon: const Icon(Icons.search, color: _blue, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  }),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: p.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _blue)),
        ));
  }

  Widget _buildFilters() {
    final p = context.pal;
    return Column(children: [
      Row(children: [
        Expanded(
            child: Text('Sort & Filter:',
                style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500))),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: p.surfaceAlt, borderRadius: BorderRadius.circular(9)),
            child: Text(_sort,
                style: const TextStyle(
                    color: _blue, fontSize: 11, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        _filterButton('Available technicians only', Icons.tune, _availableOnly,
            () => setState(() => _availableOnly = !_availableOnly)),
        const SizedBox(width: 10),
        _filterButton('Reverse sort order', Icons.swap_vert, _ascending,
            () => setState(() => _ascending = !_ascending)),
      ]),
      const SizedBox(height: 14),
      SizedBox(
          height: 27,
          child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Top rated', 'Available', 'Recommend', 'Featured']
                  .map((label) {
                final active =
                    label == 'Available' ? _availableOnly : label == _sort;
                return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() {
                              if (label == 'Available') {
                                _availableOnly = !_availableOnly;
                              } else {
                                _sort = label;
                              }
                            }),
                        child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xffe5efff)
                                    : p.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: active
                                        ? const Color(0xffbad5ff)
                                        : p.border)),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: active ? _blue : p.textPrimary)))));
              }).toList())),
    ]);
  }

  Widget _filterButton(
          String label, IconData icon, bool active, VoidCallback onTap) =>
      SizedBox(
          width: 34,
          height: 34,
          child: IconButton(
              tooltip: label,
              onPressed: onTap,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                  backgroundColor:
                      active ? const Color(0xffe5efff) : context.pal.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                      side: BorderSide(color: context.pal.border))),
              icon: Icon(icon,
                  size: 19,
                  color: active ? _blue : context.pal.textSecondary)));

  Widget _buildProviderCard(ServiceProvider provider) {
    final p = context.pal;
    final price = _priceFor(provider.category);
    final km = _distanceKm(provider);
    void open() =>
        Navigator.pushNamed(context, '/provider', arguments: provider);
    return Container(
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                  color: p.shadow.withValues(alpha: .035),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(provider.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: p.textPrimary))),
                          const SizedBox(width: 6),
                          _badge(
                              provider.available ? 'Available' : 'Unavailable',
                              provider.available
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              provider.available
                                  ? const Color(0xff00b97a)
                                  : p.textSecondary),
                          if (km != null) ...[
                            const SizedBox(width: 6),
                            _badge(
                                '${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
                                '${AppStrings.t(AppSettings.instance.distanceUnitKey)} nearby',
                                Icons.location_on,
                                _blue),
                          ],
                        ]),
                        const SizedBox(height: 5),
                        Text(
                            '${categoryLabel(provider.category)}${provider.technicianId == null ? '' : ' | Bu${provider.technicianId.toString().padLeft(4, '0')}'}',
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 10)),
                        const SizedBox(height: 13),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: provider.photoUrl?.isNotEmpty ==
                                              true
                                          ? CachedNetworkImage(
                                              imageUrl: provider.photoUrl!
                                                      .startsWith('http')
                                                  ? provider.photoUrl!
                                                  : '${ApiClient.instance.baseUrl}${provider.photoUrl}',
                                              fit: BoxFit.cover,
                                              errorWidget: (_, url, error) =>
                                                  _photoFallback())
                                          : _photoFallback())),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        provider.bannerTitle
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? provider.bannerTitle!
                                            : '${categoryLabel(provider.category)} Installation & Repair',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: p.textPrimary,
                                            height: 1.25)),
                                    const SizedBox(height: 4),
                                    Text(provider.about,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 10,
                                            height: 1.45,
                                            color: p.textSecondary)),
                                    const SizedBox(height: 5),
                                    Row(children: [
                                      const Icon(Icons.star,
                                          color: Color(0xffffa000), size: 12),
                                      const SizedBox(width: 3),
                                      Text(provider.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                              color: Color(0xffff9900),
                                              fontSize: 10)),
                                      const SizedBox(width: 3),
                                      Text('(${provider.ratingCount})',
                                          style: TextStyle(
                                              color: p.textSecondary,
                                              fontSize: 9))
                                    ]),
                                  ])),
                            ]),
                        const SizedBox(height: 10),
                        Divider(height: 1, color: p.border),
                        const SizedBox(height: 5),
                        Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    price == null
                                        ? 'PERSONALIZED SERVICE'
                                        : 'STARTS AT',
                                    style: TextStyle(
                                        color: p.textSecondary,
                                        fontSize: 8,
                                        letterSpacing: .2)),
                                const SizedBox(height: 2),
                                Text(
                                    price == null
                                        ? 'Get a quote'
                                        : '\$${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}',
                                    style: const TextStyle(
                                        color: _blue,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                              ])),
                          FilledButton(
                              onPressed: open,
                              style: FilledButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(98, 32),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 17),
                                  visualDensity: VisualDensity.compact),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Book Now',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward, size: 14)
                                  ])),
                        ]),
                      ])),
            )));
  }

  Widget _photoFallback() => ColoredBox(
      color: context.pal.surfaceAlt,
      child: const Icon(Icons.home_repair_service_outlined,
          color: _blue, size: 26));

  Widget _badge(String text, IconData icon, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 8))
      ]));

  Widget _buildStatus(IconData icon, String message, {bool retry = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(children: [
            Icon(icon, color: context.pal.textSecondary, size: 32),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: context.pal.textSecondary, fontSize: 12)),
            if (retry)
              TextButton(onPressed: _load, child: Text(AppStrings.t('retry'))),
          ]));

  Widget _buildHelp() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: _blue.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.support_agent, size: 22, color: _blue),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Need custom assistance?',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.pal.textPrimary)),
          const SizedBox(height: 3),
          Text('Speak with our service team',
              style: TextStyle(fontSize: 9, color: context.pal.textSecondary))
        ])),
        TextButton(
            onPressed: () => Navigator.pushNamed(context, '/help-support'),
            child: const Text('Get help', style: TextStyle(fontSize: 10))),
      ]));
}
