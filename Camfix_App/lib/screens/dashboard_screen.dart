import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/review.dart';
import '../models/service_provider.dart';
import '../services/api_client.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart';
import '../services/current_user.dart';
import '../services/device_location.dart';
import '../services/favorites_api.dart';
import '../services/notifications_store.dart';
import '../services/service_prices_api.dart';
import '../services/technicians_api.dart';
import '../services/token_store.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'main_shell.dart';
import 'services_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _ServiceItem {
  const _ServiceItem(this.labelKey, this.icon, this.category);
  final String labelKey;
  final IconData icon;

  /// Internal category name passed to `/services` (matches the keys in
  /// ServicesScreen's provider map / category chips).
  final String category;
}

class _HeroBanner {
  const _HeroBanner(this.titleKey, this.icon, [this.category]);
  final String titleKey;
  final IconData icon;

  /// Category to jump to on "Book now" - null just opens the Services tab.
  final String? category;
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0; // 0 = Book a service, 1 = Active Job, 2 = History
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _services = const [
    _ServiceItem('svcAirConditioner', Icons.ac_unit_rounded, 'Air Conditioner'),
    _ServiceItem(
        'svcElectrical', Icons.electrical_services_rounded, 'Electrical'),
    _ServiceItem(
        'svcApplianceRepair', Icons.handyman_rounded, 'Appliance Repair'),
    _ServiceItem('svcMotorcycle', Icons.two_wheeler_rounded, 'Motorcycle'),
    _ServiceItem('svcCar', Icons.directions_car_filled_rounded, 'Car'),
    _ServiceItem('svcWaterNetwork', Icons.plumbing_rounded, 'Water network'),
  ];

  /// Real approved technicians from `GET /api/technicians`, fetched in
  /// [initState]. Previously a hardcoded 4-entry list (Rotha Brak, Chetra
  /// Prime, Steven, B Sokha) - none of them real accounts.
  List<ServiceProvider> _technicians = const [];
  bool _techsLoading = true;
  LatLng? _userPos;

  /// Real service-category starting prices from `GET /api/service-prices`.
  List<ServicePriceInfo> _prices = const [];
  bool _pricesLoading = true;

  /// Real reviews pulled from the top-rated technicians already loaded above
  /// (there's no site-wide testimonials endpoint, so this is the honest
  /// best-effort substitute rather than inventing fake quotes).
  List<Review> _testimonials = const [];

  /// The customer's own most-recent booking, for the "Recent Booking" card.
  Booking? _recentBooking;

  static const String _supportPhone = '+855 879 084 70';

  final _heroController = PageController();
  int _heroPage = 0;
  Timer? _heroTimer;

  Timer? _clock;

  static const _heroBanners = [
    _HeroBanner('heroAcTitle', Icons.ac_unit_rounded, 'Air Conditioner'),
    _HeroBanner('heroGeneralTitle', Icons.build_rounded),
  ];

  static IconData _categoryIcon(String c) {
    switch (c) {
      case 'Electrical':
        return Icons.electrical_services_rounded;
      case 'Appliance Repair':
        return Icons.handyman_rounded;
      case 'Motorcycle':
        return Icons.two_wheeler_rounded;
      case 'Car':
        return Icons.directions_car_filled_rounded;
      case 'Water network':
        return Icons.plumbing_rounded;
      default:
        return Icons.ac_unit_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    CurrentUser.instance.addListener(_onUser);
    CurrentUser.instance.refresh();
    // Poll the backend for new booking / job notifications while signed in.
    NotificationsStore.instance.addListener(_onUser);
    NotificationsStore.instance.startPolling();
    // Same for the customer's own bookings, so Active Job / History and the
    // tracking screen reflect real status changes (a technician accepting,
    // moving, arriving, ...).
    BookingsStore.instance.startPolling();
    // Re-evaluate the time-of-day greeting once a minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadTechnicians();
    _loadPrices();
    _loadRecentBooking();
    if (!FavoritesApi.instance.isLoaded) {
      FavoritesApi.instance.list().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heroController.hasClients) return;
      _heroPage = (_heroPage + 1) % _heroBanners.length;
      _heroController.animateToPage(_heroPage,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  /// Real per-category starting prices for the "Popular Services" section.
  Future<void> _loadPrices() async {
    try {
      final list = await ServicePricesApi.instance.list();
      if (!mounted) return;
      setState(() {
        _prices = list;
        _pricesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _pricesLoading = false);
    }
  }

  /// The customer's latest booking (any status), newest first.
  Future<void> _loadRecentBooking() async {
    try {
      final list = await BookingsApi.instance.listMine();
      if (!mounted || list.isEmpty) return;
      list.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      setState(() => _recentBooking = list.first);
    } catch (_) {
      // Best-effort - the card just doesn't show if this fails.
    }
  }

  /// Pulls a few real reviews from the top-rated technicians already in
  /// [_technicians] for the "What Customers Say" section.
  Future<void> _loadTestimonials() async {
    final picks = ([..._technicians]
          ..sort((a, b) => b.rating.compareTo(a.rating)))
        .where((t) => t.technicianId != null && t.ratingCount > 0)
        .take(3);
    final collected = <Review>[];
    for (final t in picks) {
      try {
        final reviews = await TechniciansApi.instance.reviews(t.technicianId!);
        collected.addAll(reviews.where((r) => (r.comment ?? '').trim().isNotEmpty));
      } catch (_) {
        // Skip this technician's reviews on failure, try the rest.
      }
    }
    if (!mounted) return;
    setState(() => _testimonials = collected.take(4).toList());
  }

  /// Reads GPS (best-effort) and fetches the real approved-technician list.
  /// A failed GPS read still shows the list - only distance figures are
  /// affected, same fallback used by the "Nearby Technicians" map screen.
  Future<void> _loadTechnicians() async {
    final fix = await getCurrentLocation();
    if (mounted && fix.ok) {
      setState(() => _userPos = LatLng(fix.position!.latitude, fix.position!.longitude));
    }
    try {
      final list = await TechniciansApi.instance.list();
      if (!mounted) return;
      setState(() {
        _technicians = list;
        _techsLoading = false;
      });
      _loadTestimonials();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _technicians = const [];
        _techsLoading = false;
      });
    }
  }

  /// Real distance from the user to [t], or null when either position is
  /// unknown.
  double? _distanceKm(ServiceProvider t) {
    final me = _userPos;
    if (me == null || !t.hasLocation) return null;
    return distanceKmBetween(me.latitude, me.longitude, t.latitude, t.longitude);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _heroTimer?.cancel();
    _heroController.dispose();
    CurrentUser.instance.removeListener(_onUser);
    NotificationsStore.instance.removeListener(_onUser);
    BookingsStore.instance.stopPolling();
    super.dispose();
  }

  void _onUser() {
    if (mounted) setState(() {});
  }

  /// Time-of-day greeting key: morning < 12:00, afternoon < 17:00, else evening.
  String get _greetingKey {
    final h = DateTime.now().hour;
    if (h < 12) return 'goodMorning';
    if (h < 17) return 'goodAfternoon';
    return 'goodEvening';
  }

  /// First name of the signed-in user (falls back to "there").
  String get _firstName {
    final n = CurrentUser.instance.value?.displayName.trim() ?? '';
    if (n.isEmpty) return 'there';
    return n.split(RegExp(r'\s+')).first;
  }

  /// Jump to the Profile tab (tapping the avatar / greeting in the header).
  void _openProfile() => MainShell.of(context)?.goToTab(3);

  /// Open a nearby technician's profile.
  void _openTechnician(ServiceProvider t) {
    Navigator.of(context).pushNamed('/provider', arguments: t);
  }

  Future<void> _toggleFavorite(ServiceProvider t) async {
    final id = t.technicianId;
    if (id == null) return;
    final wasFavorite = FavoritesApi.instance.isFavorite(id);
    setState(() {}); // let the icon reflect the optimistic state below
    try {
      if (wasFavorite) {
        await FavoritesApi.instance.remove(id);
      } else {
        await FavoritesApi.instance.add(id);
      }
    } catch (_) {
      // Best-effort - the icon just falls back to the last known state.
    }
    if (mounted) setState(() {});
  }

  /// Real technician photo when one's been uploaded, else a generic icon.
  Widget _avatar(ServiceProvider t, {required double radius}) {
    final p = context.pal;
    final photo = t.photoUrl;
    if (photo == null || photo.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: p.surfaceAlt,
        child: Icon(Icons.person, color: AppColors.primaryBlue, size: radius),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.surfaceAlt,
      backgroundImage: NetworkImage('${ApiClient.instance.baseUrl}$photo'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: p.background,
      drawer: _buildDrawer(),
      // A single scrollable: the blue header scrolls away together with the
      // white sheet below it instead of staying pinned while only the sheet
      // scrolls independently. SliverFillRemaining still makes the sheet
      // fill the leftover viewport height when its content is short (mockup
      // p.10's curved white sheet look), but lets the whole page scroll once
      // the content is taller than the screen.
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(top: 20, bottom: 110 + bottomInset),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.blueGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                _iconCircle(Icons.menu_rounded,
                    onTap: () => _scaffoldKey.currentState?.openDrawer()),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        const UserAvatar(radius: 20, bgColor: AppColors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.t(_greetingKey),
                                  style: AppText.body),
                              Text(_firstName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bellIcon(),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.t('searchForService'),
                  hintStyle: const TextStyle(color: AppColors.hintGrey),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primaryBlue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 20),
            _heroCarousel(),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, i) => _serviceTile(_services[i]),
            ),
            const SizedBox(height: 20),
            _buildTabSwitcher(),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.white,
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }

  /// Notifications bell with an unread-count badge.
  Widget _bellIcon() {
    final unread = NotificationsStore.instance.unread;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _iconCircle(
          Icons.notifications_none_rounded,
          onTap: () async {
            await Navigator.of(context).pushNamed('/notifications');
            NotificationsStore.instance.refresh();
          },
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE23D3D),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroCarousel() {
    return SizedBox(
      height: 172,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _heroController,
              onPageChanged: (i) => setState(() => _heroPage = i),
              itemCount: _heroBanners.length,
              itemBuilder: (context, i) => _heroBannerCard(_heroBanners[i]),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_heroBanners.length, (i) {
              final active = i == _heroPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: active ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _heroBannerCard(_HeroBanner banner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.t(banner.titleKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => banner.category != null
                      ? MainShell.of(context)?.openServiceCategory(banner.category!)
                      : MainShell.of(context)?.goToTab(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                  ),
                  child: Text(AppStrings.t('bookNow'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
          Icon(banner.icon, color: AppColors.white.withValues(alpha: 0.85), size: 52),
        ],
      ),
    );
  }

  Widget _serviceTile(_ServiceItem item) {
    final p = context.pal;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => MainShell.of(context)?.openServiceCategory(item.category),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: AppColors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.t(item.labelKey),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    final p = context.pal;
    final labels = [
      AppStrings.t('bookAService'),
      AppStrings.t('activeJob'),
      AppStrings.t('history'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final bool active = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.white : p.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabIndex == 0) return _buildTechniciansSection();
    // Active / History are driven by BookingsStore, so they update the moment
    // a new booking is made.
    return AnimatedBuilder(
      animation: BookingsStore.instance,
      builder: (context, _) =>
          _tabIndex == 1 ? _buildActiveJobSection() : _buildHistorySection(),
    );
  }

  Widget _buildTechniciansSection() {
    final topRated = [..._technicians]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _sectionHeader(
            AppStrings.t('topTechnicians'),
            onSeeAll: () =>
                Navigator.of(context).pushNamed('/technicians-live'),
          ),
        ),
        const SizedBox(height: 10),
        _buildTopTechniciansRow(topRated),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _promoStripBanner(
            AppStrings.t('promo10Title'),
            AppStrings.t('promo10Subtitle'),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _sectionHeader(AppStrings.t('popularServices')),
        ),
        const SizedBox(height: 10),
        _buildPopularServicesGrid(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _sectionHeader(AppStrings.t('servicePackages')),
        ),
        const SizedBox(height: 10),
        _buildServicePackages(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                AppStrings.t('availableNearYou'),
                onSeeAll: () =>
                    Navigator.of(context).pushNamed('/technicians-live'),
              ),
              const SizedBox(height: 8),
              if (_techsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                )
              else if (_technicians.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(AppStrings.t('noTechniciansNearby'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: context.pal.textSecondary)),
                  ),
                )
              else
                ..._technicians.map(_technicianTile),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _sectionHeader(AppStrings.t('howItWorks')),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildHowItWorks(),
        ),
        if (_testimonials.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader(AppStrings.t('whatCustomersSay')),
          ),
          const SizedBox(height: 10),
          _buildTestimonials(),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildServiceGuarantee(),
        ),
        if (_recentBooking != null) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(AppStrings.t('yourRecentBooking')),
                const SizedBox(height: 10),
                _buildRecentBookingCard(_recentBooking!),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildEmergencyBanner(),
        ),
      ],
    );
  }

  Widget _buildTopTechniciansRow(List<ServiceProvider> list) {
    if (_techsLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (list.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(AppStrings.t('noTechniciansNearby'),
              style: TextStyle(fontSize: 13, color: context.pal.textSecondary)),
        ),
      );
    }
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _technicianCard(list[i]),
      ),
    );
  }

  Widget _technicianCard(ServiceProvider t) {
    final p = context.pal;
    return InkWell(
      onTap: () => _openTechnician(t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 144,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 5, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(t, radius: 20),
                const Spacer(),
                if (t.technicianId != null)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _toggleFavorite(t),
                    child: Icon(
                      FavoritesApi.instance.isFavorite(t.technicianId!)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: FavoritesApi.instance.isFavorite(t.technicianId!)
                          ? const Color(0xFFE23D3D)
                          : p.textSecondary,
                    ),
                  )
                else
                  Icon(
                    t.available ? Icons.circle : Icons.circle_outlined,
                    size: 9,
                    color: t.available ? const Color(0xFF2ECC71) : p.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(t.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5, color: p.textPrimary)),
            Text(categoryLabel(t.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 2),
                Text(t.rating.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: p.textPrimary)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text('(${t.ratingCount})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: p.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.t(t.available ? 'available' : 'unavailable'),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: t.available ? const Color(0xFF2ECC71) : p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Small full-width promo banner (mockup's pink "10% off" strip).
  Widget _promoStripBanner(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Color(0xFFB03060))),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFB03060))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB03060)),
        ],
      ),
    );
  }

  Widget _buildPopularServicesGrid() {
    if (_pricesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (_prices.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _prices.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (context, i) => _popularServiceCard(_prices[i]),
      ),
    );
  }

  Widget _popularServiceCard(ServicePriceInfo price) {
    final p = context.pal;
    return InkWell(
      onTap: () => MainShell.of(context)?.openServiceCategory(price.categoryName),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _serviceIconBadge(_categoryIcon(price.categoryName)),
            const SizedBox(height: 8),
            Text(categoryLabel(price.categoryName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: p.textPrimary)),
            const Spacer(),
            if (price.startingPrice != null)
              Text('${AppStrings.t('startingFrom')} \$${price.startingPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildServicePackages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _packageCard(
              icon: Icons.home_repair_service_rounded,
              color: const Color(0xFFE8F6EE),
              iconColor: const Color(0xFF2ECC71),
              title: AppStrings.t('homeCareBundle'),
              subtitle: AppStrings.t('homeCareBundleDesc'),
              saveLabel: AppStrings.t('save20'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _packageCard(
              icon: Icons.directions_car_filled_rounded,
              color: const Color(0xFFEAF0FF),
              iconColor: AppColors.primaryBlue,
              title: AppStrings.t('vehicleCheckup'),
              subtitle: AppStrings.t('vehicleCheckupDesc'),
              saveLabel: AppStrings.t('save15'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageCard({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String saveLabel,
  }) {
    final p = context.pal;
    return InkWell(
      onTap: () => MainShell.of(context)?.goToTab(1),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: p.textSecondary), maxLines: 2),
            const SizedBox(height: 8),
            Text(saveLabel,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: iconColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      (Icons.search, 'howItWorksStep1Title', 'howItWorksStep1Desc'),
      (Icons.calendar_month_rounded, 'howItWorksStep2Title', 'howItWorksStep2Desc'),
      (Icons.check_circle_rounded, 'howItWorksStep3Title', 'howItWorksStep3Desc'),
    ];
    return Row(
      children: List.generate(steps.length, (i) {
        final (icon, titleKey, descKey) = steps[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < steps.length - 1 ? 10 : 0),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryBlue, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                const SizedBox(height: 6),
                Text(AppStrings.t(titleKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: context.pal.textPrimary)),
                const SizedBox(height: 2),
                Text(AppStrings.t(descKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: context.pal.textSecondary)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTestimonials() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _testimonials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _testimonialCard(_testimonials[i]),
      ),
    );
  }

  Widget _testimonialCard(Review r) {
    final p = context.pal;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => Icon(Icons.star_rounded,
                  size: 14,
                  color: i < r.rating ? const Color(0xFFFFB300) : p.border),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(r.comment ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.textPrimary, height: 1.3)),
          ),
          const SizedBox(height: 6),
          Text(r.customerName?.trim().isNotEmpty == true ? r.customerName! : AppStrings.t('aCamfixCustomer'),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildServiceGuarantee() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${AppStrings.t('guaranteeVerifiedTechs')} · ${AppStrings.t('guaranteeSecureBooking')} · '
              '${AppStrings.t('guarantee7DaySupport')}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.pal.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingCard(Booking b) {
    final p = context.pal;
    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed('/booking-tracking', arguments: b.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            _serviceIconBadge(_categoryIcon(b.category)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryLabel(b.category),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5, color: p.textPrimary)),
                  Text(b.whenLabel, style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
            ),
            if (b.status == 'COMPLETED')
              OutlinedButton(
                onPressed: () => setState(() => _tabIndex = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(AppStrings.t('bookAgain'), style: const TextStyle(fontSize: 12)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(AppStrings.t(b.status == 'REQUESTED' ? 'pending' : 'live'),
                    style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('needEmergencyHelp'),
                    style: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(_supportPhone,
                    style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _callSupport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.call, size: 16),
            label: Text(AppStrings.t('callSupport'), style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:${_supportPhone.replaceAll(' ', '')}');
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.t('couldNotCall'))));
    }
  }

  Widget _technicianTile(ServiceProvider t) {
    final p = context.pal;
    return InkWell(
      onTap: () => _openTechnician(t),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(t, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(t.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: p.textPrimary)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.primaryBlue),
                    ],
                  ),
                  Text(categoryLabel(t.category),
                      style: TextStyle(color: p.textSecondary, fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(t.rating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary)),
                      Text(' (${t.ratingCount})',
                          style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 13, color: p.textSecondary),
                      Builder(builder: (_) {
                        final km = _distanceKm(t);
                        return Text(
                            km != null
                                ? ' ${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
                                    '${AppStrings.t(AppSettings.instance.distanceUnitKey)}'
                                : ' ${AppStrings.t('locationUnknown')}',
                            style: TextStyle(fontSize: 11.5, color: p.textSecondary));
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    AppStrings.t(t.available ? 'available' : 'unavailable'),
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: t.available
                            ? const Color(0xFF2ECC71)
                            : p.textSecondary)),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () => _openTechnician(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(AppStrings.t('view'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobSection() {
    final p = context.pal;
    final jobs = BookingsStore.instance.upcoming;
    if (jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          children: [
            _sectionHeader(AppStrings.t('active'),
                onSeeAll: () => setState(() => _tabIndex = 2)),
            const SizedBox(height: 44),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.apps_rounded, size: 32, color: p.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.t('activeJobsEmpty'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => setState(() => _tabIndex = 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: Text(AppStrings.t('bookAService'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppStrings.t('active'),
              onSeeAll: () => setState(() => _tabIndex = 2)),
          const SizedBox(height: 8),
          for (final b in jobs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _jobCard(
                icon: _categoryIcon(b.category),
                onTap: () => Navigator.of(context)
                    .pushNamed('/booking-tracking', arguments: b.id),
                title: categoryLabel(b.category),
                subtitle: b.whenLabel,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      AppStrings.t(
                          b.status == 'REQUESTED' ? 'pending' : 'live'),
                      style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final p = context.pal;
    final jobs = BookingsStore.instance.completed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.t('completed'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary)),
          const SizedBox(height: 8),
          if (jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(AppStrings.t('noCompletedJobs'),
                    style: TextStyle(color: p.textSecondary)),
              ),
            )
          else
            for (final b in jobs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context)
                        .pushNamed('/booking-tracking', arguments: b.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.border),
                        boxShadow: [
                          BoxShadow(
                              color: p.shadow,
                              blurRadius: 5,
                              offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _serviceIconBadge(_categoryIcon(b.category)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(categoryLabel(b.category),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: p.textPrimary)),
                                    Text(b.whenLabel,
                                        style: TextStyle(
                                            color: p.textSecondary,
                                            fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: p.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _chipButton(AppStrings.t('reorder')),
                              const SizedBox(width: 8),
                              _chipButton(AppStrings.t('ratings'),
                                  filled: false,
                                  onTap: () => Navigator.of(context).pushNamed(
                                      '/booking-tracking',
                                      arguments: b.id)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _chipButton(String label, {bool filled = true, VoidCallback? onTap}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primaryBlue
            : AppColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? AppColors.white : AppColors.primaryBlue,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(20), onTap: onTap, child: chip),
    );
  }

  Widget _serviceIconBadge(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.white, size: 22),
    );
  }

  Widget _jobCard({
    required String title,
    required String subtitle,
    required Widget trailing,
    IconData icon = Icons.ac_unit_rounded,
    VoidCallback? onTap,
  }) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 5, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            _serviceIconBadge(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: p.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
            trailing,
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    final p = context.pal;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.textPrimary)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(AppStrings.t('seeAll'),
                style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5)),
          ),
      ],
    );
  }

  // --- Hamburger drawer ----------------------------------------------------

  Widget _buildDrawer() {
    final p = context.pal;
    final user = CurrentUser.instance.value;
    return Drawer(
      backgroundColor: p.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _openProfile();
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration:
                    const BoxDecoration(gradient: AppColors.blueGradient),
                child: Row(
                  children: [
                    const UserAvatar(radius: 26, bgColor: AppColors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? AppStrings.t('camfixUser'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          if ((user?.email ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color:
                                      AppColors.white.withValues(alpha: 0.85),
                                  fontSize: 12.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.white.withValues(alpha: 0.85)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerRow(
                    icon: Icons.favorite_border_rounded,
                    label: AppStrings.t('favorites'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/favorites');
                    },
                  ),
                  _drawerRow(
                    icon: Icons.notifications_none_rounded,
                    label: AppStrings.t('notifications'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await Navigator.of(context).pushNamed('/notifications');
                      NotificationsStore.instance.refresh();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.help_outline_rounded,
                    label: AppStrings.t('helpAndSupport'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/help-support');
                    },
                  ),
                  Divider(height: 24, color: p.border),
                  _drawerLanguageRow(p),
                  const SizedBox(height: 4),
                  _drawerDarkModeRow(p),
                  Divider(height: 24, color: p.border),
                  _drawerRow(
                    icon: Icons.logout_rounded,
                    label: AppStrings.t('logout'),
                    color: const Color(0xFFE5484D),
                    onTap: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final p = context.pal;
    final tint = color ?? p.textPrimary;
    return ListTile(
      leading: Icon(icon, color: tint),
      title: Text(label,
          style: TextStyle(color: tint, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _drawerLanguageRow(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.translate_rounded, color: p.textPrimary),
          const SizedBox(width: 32),
          Expanded(
            child: Text(AppStrings.t('language'),
                style: TextStyle(
                    color: p.textPrimary, fontWeight: FontWeight.w600)),
          ),
          _langChip(p, AppLang.en, 'EN'),
          const SizedBox(width: 6),
          _langChip(p, AppLang.km, 'ខ្មែរ'),
        ],
      ),
    );
  }

  Widget _langChip(AppPalette p, AppLang lang, String label) {
    final active = AppSettings.instance.lang == lang;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        AppSettings.instance.setLang(lang);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryBlue
              : AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.white : AppColors.primaryBlue)),
      ),
    );
  }

  Widget _drawerDarkModeRow(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.dark_mode_outlined, color: p.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppStrings.t('darkMode'),
                style: TextStyle(
                    color: p.textPrimary, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: AppSettings.instance.isDark,
            onChanged: (v) {
              AppSettings.instance.setDarkMode(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.t('logoutConfirmTitle')),
        content: Text(AppStrings.t('logoutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
            child: Text(AppStrings.t('logout')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await TokenStore.instance.clear();
    CurrentUser.instance.clear();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
