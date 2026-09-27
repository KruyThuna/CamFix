import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../models/review.dart';
import '../models/service_provider.dart';
import '../models/technician_service_listing.dart';
import '../services/api_client.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart';
import '../services/current_user.dart';
import '../services/device_location.dart';
import '../services/favorites_api.dart';
import '../services/notifications_store.dart';
import '../services/osrm_api.dart';
import '../services/service_prices_api.dart';
import '../services/technicians_api.dart';
import '../services/token_store.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'booking_sheet.dart';
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
  const _HeroBanner(this.titleKey, this.icon, [this.category, this.imageAsset])
      : rawTitle = null,
        imageNetworkUrl = null,
        provider = null;

  /// A technician's own posted banner: real photo + free-form headline,
  /// tapping through to their profile instead of a category/tab.
  const _HeroBanner.technician({
    required String title,
    required this.imageNetworkUrl,
    required this.provider,
  })  : titleKey = '',
        icon = Icons.campaign_outlined,
        category = null,
        imageAsset = null,
        rawTitle = title;

  final String titleKey;
  final IconData icon;

  /// Category to jump to on "Book now" - null just opens the Services tab.
  final String? category;

  /// Photo bleeding off the right/bottom edge of the card, in place of
  /// [icon], when this slide has one.
  final String? imageAsset;

  /// Literal text (not an i18n key) for a technician-posted banner.
  final String? rawTitle;

  /// Network image for a technician-posted banner, in place of [imageAsset].
  final String? imageNetworkUrl;

  /// Technician to open on tap, for a technician-posted banner.
  final ServiceProvider? provider;
}

/// One checked line in the "Why CAM FIX" benefits card - real, platform-wide
/// facts (technician approval, real ratings, live tracking), never invented
/// numeric claims like a fake discount or membership perk.
class _BenefitCheckRow extends StatelessWidget {
  const _BenefitCheckRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF91F3DC)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11.5, height: 1.3, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _services = const [
    _ServiceItem('svcElectrical', Icons.bolt_rounded, 'Electrical'),
    _ServiceItem('svcWaterNetwork', Icons.plumbing_rounded, 'Water network'),
    _ServiceItem('svcAirConditioner', Icons.ac_unit_rounded, 'Air Conditioner'),
    _ServiceItem(
        'svcApplianceRepair', Icons.kitchen_outlined, 'Appliance Repair'),
    _ServiceItem('svcCar', Icons.directions_car_filled_rounded, 'Car'),
    _ServiceItem('svcMotorcycle', Icons.two_wheeler_rounded, 'Motorcycle'),
  ];

  /// Real approved technicians from `GET /api/technicians`, fetched in
  /// [initState]. Previously a hardcoded 4-entry list (Rotha Brak, Chetra
  /// Prime, Steven, B Sokha) - none of them real accounts.
  List<ServiceProvider> _technicians = const [];
  bool _techsLoading = true;
  LatLng? _userPos;

  /// Real reviews pulled from the top-rated technicians already loaded above
  /// (there's no site-wide testimonials endpoint, so this is the honest
  /// best-effort substitute rather than inventing fake quotes).
  List<Review> _testimonials = const [];

  /// The customer's own most-recent booking, for the "Recent Booking" card.
  Booking? _recentBooking;

  /// Newest still-open booking (from the polled [BookingsStore]) - the only
  /// thing the top "Tracking" card is ever shown for.
  Booking? get _activeBooking {
    final open = [...BookingsStore.instance.upcoming]..sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return open.isEmpty ? null : open.first;
  }

  /// Real road ETA for [_activeBooking] while the technician is on the way.
  OsrmRoute? _eta;
  int? _etaBookingId;
  LatLng? _etaFrom;

  /// Real service listings (title + price) posted by approved technicians,
  /// for "Popular Services" - most-completed first.
  List<(TechnicianServiceListing, ServiceProvider)> _popular = const [];

  static const String _supportPhone = '+855 879 084 70';

  final _heroController = PageController();
  int _heroPage = 0;
  Timer? _heroTimer;

  Timer? _clock;

  static const _staticHeroBanners = [
    _HeroBanner('heroAcTitle', Icons.ac_unit_rounded, 'Air Conditioner',
        'assets/images/hero_ac_technician.png'),
    _HeroBanner('heroGeneralTitle', Icons.build_rounded),
  ];

  /// The static promo slides plus one real slide per approved technician
  /// who has posted a banner (`GET /api/technicians` -> `bannerUrl`).
  List<_HeroBanner> get _heroBanners => [
        ..._staticHeroBanners,
        for (final t in _technicians)
          if (t.bannerUrl != null)
            _HeroBanner.technician(
              title: (t.bannerTitle?.trim().isNotEmpty ?? false)
                  ? t.bannerTitle!.trim()
                  : t.name,
              imageNetworkUrl: t.bannerUrl!,
              provider: t,
            ),
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
    BookingsStore.instance.addListener(_onBookings);
    BookingsStore.instance.startPolling();
    // Re-evaluate the time-of-day greeting once a minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadTechnicians();
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
        collected
            .addAll(reviews.where((r) => (r.comment ?? '').trim().isNotEmpty));
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
      setState(() =>
          _userPos = LatLng(fix.position!.latitude, fix.position!.longitude));
    }
    try {
      final list = await TechniciansApi.instance.list();
      if (!mounted) return;
      setState(() {
        _technicians = list;
        _techsLoading = false;
      });
      _loadTestimonials();
      _loadPopularListings(list);
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
    return distanceKmBetween(
        me.latitude, me.longitude, t.latitude, t.longitude);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _heroTimer?.cancel();
    _heroController.dispose();
    CurrentUser.instance.removeListener(_onUser);
    NotificationsStore.instance.removeListener(_onUser);
    BookingsStore.instance.removeListener(_onBookings);
    BookingsStore.instance.stopPolling();
    super.dispose();
  }

  void _onUser() {
    if (mounted) setState(() {});
  }

  /// Bookings changed (poll): redraw the tracking card, and refresh the road
  /// ETA only when the technician moved a meaningful distance.
  void _onBookings() {
    if (!mounted) return;
    setState(() {});
    final b = _activeBooking;
    if (b == null ||
        b.isSelfDrop ||
        b.status != 'ON_THE_WAY' ||
        !b.hasTechnicianFix ||
        !b.hasDestination) {
      _eta = null;
      return;
    }
    final from = LatLng(b.technicianLat!, b.technicianLng!);
    if (_etaBookingId == b.id &&
        _etaFrom != null &&
        const Distance().as(LengthUnit.Meter, _etaFrom!, from) < 80) {
      return;
    }
    _etaBookingId = b.id;
    _etaFrom = from;
    OsrmApi.instance
        .route(origin: from, destination: LatLng(b.lat!, b.lng!))
        .then((r) {
      if (mounted && r != null) setState(() => _eta = r.routes.first);
    });
  }

  /// Every approved technician's own priced listings, most-booked first.
  Future<void> _loadPopularListings(List<ServiceProvider> techs) async {
    final withId = techs.where((t) => t.technicianId != null).take(10);
    final results = await Future.wait(withId.map((t) async {
      try {
        final ls = await TechniciansApi.instance.services(t.technicianId!);
        return [for (final l in ls) (l, t)];
      } catch (_) {
        return <(TechnicianServiceListing, ServiceProvider)>[];
      }
    }));
    final all = results.expand((e) => e).toList()
      ..sort((a, b) {
        final byJobs = b.$1.completedJobCount.compareTo(a.$1.completedJobCount);
        return byJobs != 0 ? byJobs : b.$2.rating.compareTo(a.$2.rating);
      });
    if (mounted) setState(() => _popular = all.take(8).toList());
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
      backgroundImage:
          CachedNetworkImageProvider('${ApiClient.instance.baseUrl}$photo'),
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
      // scrolls independently. Plain SliverToBoxAdapter (not
      // SliverFillRemaining(hasScrollBody:false)) because that variant makes
      // its child report intrinsic height, which crashes
      // (RenderShrinkWrappingViewport does not support intrinsic dimensions)
      // as soon as any shrink-wrapped GridView/ListView.builder - like the
      // Services grid or the Popular Services grid - is anywhere in the
      // subtree.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.only(top: 4, bottom: 110 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppLayout.pageGutter,
                        ),
                        child: _heroCarousel(),
                      ),
                      const SizedBox(height: 20),
                      _buildServicesSection(),
                      _buildReferenceSections(),
                      const SizedBox(height: 20),
                      _buildTechniciansSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final p = context.pal;
    return SafeArea(
        bottom: false,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // Brand mark doubles as the drawer (menu) button.
                InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  customBorder: const CircleBorder(),
                  child: Tooltip(
                    message: 'Menu',
                    child: ClipOval(
                      child: Image.asset(
                          'assets/images/camfix_mascot_logo.webp',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('CAMFIX',
                        style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 18,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w900))),
                IconButton(
                    tooltip: 'Favorites',
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/favorites'),
                    icon: const Icon(Icons.favorite_rounded,
                        color: Colors.redAccent)),
                _bellIcon(),
                IconButton(
                    tooltip: AppStrings.t('profile'),
                    onPressed: _openProfile,
                    icon: const Icon(Icons.person_rounded,
                        color: AppColors.primaryBlue)),
              ]),
              InkWell(
                  onTap: _openProfile,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                            child: Text(
                                AppSettings.instance.defaultAddress ??
                                    AppStrings.t('pickLocation'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: p.textPrimary))),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                      ]))),
              TextField(
                  readOnly: true,
                  onTap: () => Navigator.of(context).pushNamed('/search'),
                  decoration: InputDecoration(
                      hintText: AppStrings.t('searchForService'),
                      hintStyle:
                          TextStyle(fontSize: 12, color: p.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: p.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              if (_activeBooking != null) ...[
                const SizedBox(height: 14),
                _activeTrackingCard(_activeBooking!),
              ],
              const SizedBox(height: 20),
              Text('${AppStrings.t(_greetingKey)}, $_firstName',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 3),
              Text('What needs fixing in your home today?',
                  style: TextStyle(fontSize: 11, color: p.textSecondary)),
            ])));
  }

  /// Top "Tracking" card for the newest open booking - every value is real:
  /// booking id, technician (+ their real rating when they have one), the
  /// road ETA from OSRM while they're on the way, and the status progress.
  Widget _activeTrackingCard(Booking booking) {
    final p = context.pal;
    final techName = booking.technicianName?.trim();
    ServiceProvider? tech;
    for (final t in _technicians) {
      if (t.technicianId != null && t.technicianId == booking.technicianId) {
        tech = t;
      }
    }
    final desc = booking.description;
    final cut = desc.indexOf(' - booked via app');
    final serviceTitle =
        cut > 0 ? desc.substring(0, cut) : categoryLabel(booking.category);

    // Dispatched -> On the way -> Arrived (Self Drop: Accepted -> Ready -> Received).
    final selfDrop = booking.isSelfDrop;
    final progress = switch (booking.status) {
      'REQUESTED' => 0.06,
      'ASSIGNED' => 0.22,
      'ON_THE_WAY' => 0.58,
      _ => 1.0,
    };
    final km = booking.hasTechnicianFix && booking.hasDestination && !selfDrop
        ? (_eta?.km ??
            distanceKmBetween(booking.technicianLat!, booking.technicianLng!,
                booking.lat!, booking.lng!))
        : null;
    final steps = selfDrop
        ? [
            AppStrings.t('stepAccepted'),
            AppStrings.t('stepReadyForDropOff'),
            AppStrings.t('stepItemReceived'),
          ]
        : [
            AppStrings.t('stepDispatched'),
            booking.status == 'ON_THE_WAY' && km != null
                ? '${AppStrings.t('stepOnTheWay')} (${km.toStringAsFixed(1)} km)'
                : AppStrings.t('stepOnTheWay'),
            AppStrings.t('stepArrived'),
          ];
    final activeStep = switch (booking.status) {
      'REQUESTED' || 'ASSIGNED' => 0,
      'ON_THE_WAY' => 1,
      _ => 2,
    };
    final pill = booking.status == 'ON_THE_WAY' && _eta != null && !selfDrop
        ? '${AppStrings.t('inLabel')} ${_eta!.minutes} ${AppStrings.t('minShort')}'
        : booking.status == 'REQUESTED'
            ? AppStrings.t('stepPending')
            : (selfDrop && booking.scheduledAt != null)
                ? booking.whenLabel
                : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF16A873)),
          const SizedBox(width: 6),
          const Text('TRACKING',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16A873))),
          Text('  •  #${booking.id}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.textSecondary)),
          const Spacer(),
          if (pill != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text(pill,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue)),
              ]),
            ),
        ]),
        Divider(height: 20, color: p.border),
        Row(children: [
          tech != null
              ? _avatar(tech, radius: 22)
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: p.surfaceAlt,
                  child: const Icon(Icons.home_repair_service_rounded,
                      color: AppColors.primaryBlue, size: 22),
                ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: techName?.isNotEmpty == true
                          ? techName!
                          : AppStrings.t('waitingForTechnicianShort'),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary)),
                  if (tech != null && tech.ratingCount > 0)
                    TextSpan(
                        text: '  (${tech.rating.toStringAsFixed(1)} ★)',
                        style:
                            TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(serviceTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue)),
              Text(categoryLabel(booking.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Text(steps[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == steps.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          i <= activeStep ? FontWeight.w700 : FontWeight.w500,
                      color: i <= activeStep
                          ? AppColors.primaryBlue
                          : p.textSecondary)),
            ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: p.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushNamed('/booking-tracking', arguments: booking.id),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(AppStrings.t('trackLiveMap')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.primaryBlue,
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if ((booking.technicianPhone ?? '').isNotEmpty) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () =>
                  launchUrl(Uri.parse('tel:${booking.technicianPhone}')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                side: BorderSide(color: p.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Icon(Icons.call_rounded, size: 18, color: p.textPrimary),
            ),
          ],
          // Real per-booking chat - only once a technician is assigned.
          if (booking.technicianId != null) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed(
                '/chat-thread',
                arguments: ChatThreadArgs(
                  jobId: booking.id,
                  name:
                      booking.technicianName ?? AppStrings.t('technicianLabel'),
                  category: booking.category,
                  phone: booking.technicianPhone,
                  technicianId: booking.technicianId,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                side: BorderSide(color: p.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Icon(Icons.chat_rounded, size: 18, color: p.textPrimary),
            ),
          ],
        ]),
      ]),
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
    final p = context.pal;
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
                  color: active
                      ? AppColors.primaryBlue
                      : p.textSecondary.withValues(alpha: 0.28),
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
    final hasPhoto =
        banner.imageAsset != null || banner.imageNetworkUrl != null;
    final p = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto ? p.surfaceAlt : AppColors.primaryBlue,
          gradient: hasPhoto ? null : AppColors.blueGradient,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.imageAsset != null)
              Positioned.fill(
                child: Image.asset(banner.imageAsset!, fit: BoxFit.cover),
              ),
            if (banner.imageNetworkUrl != null)
              Positioned.fill(
                child: Image.network(
                  '${ApiClient.instance.baseUrl}${banner.imageNetworkUrl!}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            if (!hasPhoto)
              // No photo for this slide - add depth with a soft oversized
              // watermark of the same icon instead of a flat solid card.
              Positioned(
                right: -24,
                bottom: -30,
                child: Icon(banner.icon,
                    size: 150, color: AppColors.white.withValues(alpha: 0.10)),
              ),
            if (hasPhoto)
              // A technician's own banner photo can contain anything
              // (including its own baked-in text) - this scrim has to fully
              // obscure that under our title, not just tint it, or the two
              // texts visually collide.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.deepBlue.withValues(alpha: 0.92),
                        AppColors.deepBlue.withValues(alpha: 0.05),
                      ],
                      stops: const [0.0, 0.72],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(banner.rawTitle ?? AppStrings.t(banner.titleKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                shadows: hasPhoto
                                    ? [
                                        Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                            blurRadius: 6,
                                            offset: const Offset(0, 1)),
                                      ]
                                    : null)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => banner.provider != null
                              ? Navigator.of(context).pushNamed('/provider',
                                  arguments: banner.provider)
                              : banner.category != null
                                  ? MainShell.of(context)
                                      ?.openServiceCategory(banner.category!)
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
                  if (!hasPhoto)
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.25)),
                      ),
                      child:
                          Icon(banner.icon, color: AppColors.white, size: 34),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Categories whose icon circle uses the mint accent instead of lavender -
  /// purely a decorative alternation, same two tones already used for the
  /// "Common Fixes" icon badges below.
  static const _mintCategories = {'Water network', 'Car'};

  Widget _serviceTile(_ServiceItem item, {String? subtitle}) {
    final p = context.pal;
    final mint = _mintCategories.contains(item.category);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 5, offset: const Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              MainShell.of(context)?.openServiceCategory(item.category),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: mint
                        ? const Color(0xFFD4F8F1)
                        : const Color(0xFFE8EBFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon,
                      color: mint
                          ? const Color(0xFF148E89)
                          : AppColors.primaryBlue,
                      size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.t(item.labelKey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "Services" header + grid - always visible above the tab switcher,
  /// regardless of which tab (Book a service / Active Job / History) is
  /// selected.
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _sectionHeader(
            'Categories',
            onSeeAll: () => MainShell.of(context)?.goToTab(1),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLayout.pageGutter),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale =
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
              return FutureBuilder<List<ServicePriceInfo>>(
                future: ServicePricesApi.instance.list(),
                builder: (context, snapshot) {
                  final prices = {
                    for (final price
                        in snapshot.data ?? const <ServicePriceInfo>[])
                      price.categoryName: price.startingPrice,
                  };
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: constraints.maxWidth < 300 ? 8 : 10,
                      mainAxisExtent: 100 + ((textScale - 1) * 24),
                    ),
                    itemBuilder: (context, i) {
                      final item = _services[i];
                      final price = prices[item.category];
                      return _serviceTile(item,
                          subtitle: price == null
                              ? null
                              : 'From \$${price.toStringAsFixed(0)}');
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Book a service / Active Job / History segmented switcher.
  Widget _buildReferenceSections() {
    final p = context.pal;
    const fixes = [
      ('Leaking Pipe Repair', 'Water network', Icons.water_drop_outlined),
      ('AC Refrigerant Recharge', 'Air Conditioner', Icons.ac_unit_rounded),
      ('Circuit Breaker Tripping', 'Electrical', Icons.bolt_rounded),
      ('Drain Unclogging', 'Water network', Icons.plumbing_rounded),
    ];
    const offerCount = 2;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      Container(
          color: p.background,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _sectionHeader('Special Offers & Benefits',
                    onSeeAll: () => MainShell.of(context)?.goToTab(1))),
            const SizedBox(height: 12),
            SizedBox(
                height: 240,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: offerCount,
                    separatorBuilder: (_, i) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final ink = i == 0 ? p.textPrimary : Colors.white;
                      return Container(
                          width: 270,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: i == 0 ? p.surface : AppColors.deepBlue,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: p.shadow,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ]),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: i == 0
                                            ? AppColors.primaryBlue
                                                .withValues(alpha: 0.1)
                                            : const Color(0xFF91F3DC)
                                                .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                          i == 0
                                              ? 'SEASONAL SERVICE'
                                              : 'WHY CAM FIX',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: i == 0
                                                  ? AppColors.primaryBlue
                                                  : const Color(0xFF91F3DC))),
                                    ),
                                    Icon(
                                        i == 0
                                            ? Icons.ac_unit_rounded
                                            : Icons.verified_outlined,
                                        size: 18,
                                        color: i == 0
                                            ? AppColors.primaryBlue
                                            : const Color(0xFF91F3DC)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                    i == 0
                                        ? 'AC Inspection & Care'
                                        : 'Built on real reviews',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: ink,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                if (i == 0)
                                  Text(
                                      'Keep your home cool with professional AC maintenance.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: ink))
                                else
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _BenefitCheckRow(
                                          'Technicians reviewed before approval'),
                                      _BenefitCheckRow(
                                          'Ratings from real completed jobs'),
                                      _BenefitCheckRow(
                                          'Track your booking in real time'),
                                    ],
                                  ),
                                const Spacer(),
                                SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: i == 0
                                                ? AppColors.primaryBlue
                                                : const Color(0xFF91F3DC),
                                            foregroundColor: i == 0
                                                ? Colors.white
                                                : AppColors.deepBlue,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10))),
                                        onPressed: () => i == 0
                                            ? MainShell.of(context)
                                                ?.openServiceCategory(
                                                    'Air Conditioner')
                                            : MainShell.of(context)?.goToTab(1),
                                        child: Text(
                                            i == 0
                                                ? 'Find AC specialists'
                                                : 'Explore services',
                                            style: const TextStyle(
                                                fontSize: 12)))),
                              ]));
                    })),
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only real technician listings - hidden until any exist.
                if (_popular.isNotEmpty) ...[
                  _sectionHeader('Popular Services',
                      onSeeAll: () => MainShell.of(context)?.goToTab(1)),
                  const SizedBox(height: 12),
                  _buildPopularServicesRow(),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Common Fixes & Fast Booking',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary)),
                    Text('Instant Estimates',
                        style: TextStyle(fontSize: 11, color: p.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ServicePriceInfo>>(
                  future: ServicePricesApi.instance.list(),
                  builder: (context, snapshot) {
                    final prices = {
                      for (final price
                          in snapshot.data ?? const <ServicePriceInfo>[])
                        price.categoryName: price.startingPrice,
                    };
                    return Column(children: [
                      for (final fix in fixes)
                        Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            decoration: BoxDecoration(
                                border: Border.all(color: p.border),
                                borderRadius: BorderRadius.circular(12)),
                            child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    leading: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                            color: fix.$2 == 'Water network'
                                                ? const Color(0xFFD4F8F1)
                                                : const Color(0xFFE8EBFF),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Icon(fix.$3,
                                            size: 20,
                                            color: fix.$2 == 'Water network'
                                                ? const Color(0xFF148E89)
                                                : AppColors.primaryBlue)),
                                    title: Text(fix.$1,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                        prices[fix.$2] != null ? 'From \$${prices[fix.$2]!.toStringAsFixed(0)}' : 'View specialists',
                                        style: const TextStyle(fontSize: 10)),
                                    trailing: TextButton(style: TextButton.styleFrom(backgroundColor: const Color(0xFFE8EBFF), minimumSize: const Size(44, 32)), onPressed: () => MainShell.of(context)?.openServiceCategory(fix.$2), child: const Text('Book', style: TextStyle(fontSize: 10))),
                                    onTap: () => MainShell.of(context)?.openServiceCategory(fix.$2)))),
                    ]);
                  },
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => MainShell.of(context)?.goToTab(1),
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.verified_user_outlined,
                            color: Color(0xFF148E89)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verified technicians',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary)),
                            Text(
                                'Every technician is reviewed before they can take jobs',
                                style: TextStyle(
                                    fontSize: 10.5, color: p.textSecondary)),
                          ],
                        )),
                        Icon(Icons.chevron_right, color: p.textSecondary),
                      ])),
                ),
              ])),
    ]);
  }

  Widget _buildPopularServicesRow() {
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _popular.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            _popularServiceCard(_popular[i].$1, _popular[i].$2),
      ),
    );
  }

  /// One technician's real listing: its title and price, the technician's
  /// real rating (only when they have ratings), and their own banner photo
  /// when they've uploaded one. "Book" opens the booking sheet on exactly
  /// this listing.
  Widget _popularServiceCard(TechnicianServiceListing l, ServiceProvider t) {
    final p = context.pal;
    final photo = l.photoUrl ?? t.bannerUrl ?? t.photoUrl;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/provider', arguments: t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 198,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 88,
                width: double.infinity,
                child: photo != null
                    ? CachedNetworkImage(
                        imageUrl: '${ApiClient.instance.baseUrl}$photo',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _popularPlaceholder(t.category),
                      )
                    : _popularPlaceholder(t.category),
              ),
            ),
            if (t.ratingCount > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB300), size: 13),
                    const SizedBox(width: 2),
                    Text('${t.rating.toStringAsFixed(1)} (${t.ratingCount})',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                  ]),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.engineering_rounded,
                    size: 13, color: p.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                      l.completedJobCount > 0
                          ? '${t.name} • ${l.completedJobCount} done'
                          : t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STARTING',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: p.textSecondary)),
                      const SizedBox(height: 1),
                      Text(
                          '\$${l.price.toStringAsFixed(l.price == l.price.roundToDouble() ? 0 : 2)}',
                          style: TextStyle(
                              fontSize: 20,
                              height: 0.95,
                              fontWeight: FontWeight.w900,
                              color: p.textPrimary)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => showBookingSheet(context, t, listing: l),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(54, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Book',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _popularPlaceholder(String category) => Container(
        color: const Color(0xFFE8EBFF),
        alignment: Alignment.center,
        child: Icon(_categoryIcon(category),
            size: 36, color: AppColors.primaryBlue),
      );

  Widget _buildTechniciansSection() {
    final topRated = [..._technicians]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final nearby = [..._technicians]..sort((a, b) {
        if (a.available != b.available) return a.available ? -1 : 1;
        final aDistance = _distanceKm(a);
        final bDistance = _distanceKm(b);
        if (aDistance != null && bDistance != null) {
          return aDistance.compareTo(bDistance);
        }
        if (aDistance != null) return -1;
        if (bDistance != null) return 1;
        return b.rating.compareTo(a.rating);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _sectionHeader(
            AppStrings.t('topTechnicians'),
            roundButton: true,
            onSeeAll: () =>
                Navigator.of(context).pushNamed('/technicians-live'),
          ),
        ),
        const SizedBox(height: 10),
        _buildTopTechniciansRow(topRated),
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
                ...nearby.take(3).map(_technicianTile),
            ],
          ),
        ),
        const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sectionHeader(
              AppStrings.t('whatCustomersSay'),
              onSeeAll: () =>
                  Navigator.of(context).pushNamed('/technicians-live'),
            ),
          ),
          const SizedBox(height: 8),
          _buildTestimonials(),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildServiceGuarantee(),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildLowerActions(),
        ),
      ],
    );
  }

  /// Recent booking card (if any) + the emergency-support banner, stacked
  /// below the Service Guarantee strip.
  Widget _buildLowerActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final recent = _recentBooking;
        if (recent == null) return _buildEmergencyBanner();

        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final useCompactRow = constraints.maxWidth >= 350 && textScale <= 1.2;
        if (useCompactRow) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildRecentBookingCompactCard(recent)),
                const SizedBox(width: 10),
                Expanded(child: _buildEmergencyCompactBanner()),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(AppStrings.t('yourRecentBooking')),
            const SizedBox(height: 10),
            _buildRecentBookingCard(recent),
            const SizedBox(height: 16),
            _buildEmergencyBanner(),
          ],
        );
      },
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
      height: 216,
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
    final hasPhoto = t.photoUrl != null && t.photoUrl!.isNotEmpty;
    final photoProvider = hasPhoto
        ? CachedNetworkImageProvider(
            '${ApiClient.instance.baseUrl}${t.photoUrl}')
        : null;
    return InkWell(
      onTap: () => _openTechnician(t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 144,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 5, offset: const Offset(0, 1)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 84,
                    width: double.infinity,
                    child: hasPhoto
                        ? Image(image: photoProvider!, fit: BoxFit.cover)
                        : Container(
                            color: p.surfaceAlt,
                            child: const Icon(Icons.person,
                                color: AppColors.primaryBlue, size: 36),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: p.textPrimary)),
                      Text(categoryLabel(t.category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5, color: p.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text(t.rating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text('(${t.ratingCount})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: p.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (_) {
                        final km = _distanceKm(t);
                        if (km == null) {
                          return Text(
                            AppStrings.t(
                                t.available ? 'available' : 'unavailable'),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: t.available
                                    ? const Color(0xFF2ECC71)
                                    : p.textSecondary),
                          );
                        }
                        return Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 11, color: p.textSecondary),
                            Expanded(
                              child: Text(
                                ' ${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
                                '${AppStrings.t(AppSettings.instance.distanceUnitKey)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10.5, color: p.textSecondary),
                              ),
                            ),
                            Text(
                              AppStrings.t(
                                  t.available ? 'available' : 'unavailable'),
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: t.available
                                      ? const Color(0xFF2ECC71)
                                      : p.textSecondary),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            // Small profile-photo bubble overlapping the boundary between
            // the cover photo and the text below, like the mockup's card.
            Positioned(
              left: 10,
              top: 84 - 18,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: p.surfaceAlt,
                  backgroundImage: photoProvider,
                  child: hasPhoto
                      ? null
                      : const Icon(Icons.person,
                          color: AppColors.primaryBlue, size: 18),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: t.technicianId != null
                  ? InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _toggleFavorite(t),
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.white,
                        child: Icon(
                          FavoritesApi.instance.isFavorite(t.technicianId!)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 14,
                          color:
                              FavoritesApi.instance.isFavorite(t.technicianId!)
                                  ? const Color(0xFFE23D3D)
                                  : p.textSecondary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      (Icons.search, 'howItWorksStep1Title', 'howItWorksStep1Desc'),
      (
        Icons.calendar_month_rounded,
        'howItWorksStep2Title',
        'howItWorksStep2Desc'
      ),
      (Icons.build_rounded, 'howItWorksStep3Title', 'howItWorksStep3Desc'),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(steps.length, (i) {
          final (icon, titleKey, descKey) = steps[i];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < steps.length - 1 ? 8 : 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon,
                                color: AppColors.primaryBlue, size: 24),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(AppStrings.t(titleKey),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: context.pal.textPrimary)),
                    const SizedBox(height: 3),
                    Text(AppStrings.t(descKey),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 9.2,
                            height: 1.25,
                            color: context.pal.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTestimonials() {
    return SizedBox(
      height: 152,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final railWidth = constraints.maxWidth - 40;
          final cardWidth = (railWidth * 0.47).clamp(132.0, 164.0).toDouble();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _testimonials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) =>
                _testimonialCard(_testimonials[i], width: cardWidth),
          );
        },
      ),
    );
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  /// "Aug 15, 2024" - no `intl` dependency in this app, so a small manual
  /// formatter instead of pulling it in for one label.
  String _shortDate(DateTime d) =>
      '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

  Widget _testimonialCard(Review r, {required double width}) {
    final p = context.pal;
    final name = r.customerName?.trim().isNotEmpty == true
        ? r.customerName!
        : AppStrings.t('aCamfixCustomer');
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: p.surfaceAlt,
                child: const Icon(Icons.person,
                    size: 14, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(Icons.star_rounded,
                  size: 12,
                  color: i < r.rating ? const Color(0xFFFFB300) : p.border),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(r.comment ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10.3, color: p.textPrimary, height: 1.25)),
          ),
          if (r.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(_shortDate(r.createdAt!),
                style: TextStyle(fontSize: 9, color: p.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceGuarantee() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.09),
            AppColors.cyan.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t('serviceGuarantee'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: context.pal.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${AppStrings.t('guaranteeVerifiedTechs')} · ${AppStrings.t('guaranteeSecureBooking')} · '
                  '${AppStrings.t('guarantee7DaySupport')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.3,
                    color: context.pal.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.primaryBlue, size: 18),
        ],
      ),
    );
  }

  Widget _buildRecentBookingCompactCard(Booking b) {
    final p = context.pal;
    final completed = b.status == 'COMPLETED';
    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed('/booking-tracking', arguments: b.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('yourRecentBooking'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _serviceIconBadge(_categoryIcon(b.category)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel(b.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        b.whenLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 10.5, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: completed
                    ? () =>
                        MainShell.of(context)?.openServiceCategory(b.category)
                    : () => Navigator.of(context)
                        .pushNamed('/booking-tracking', arguments: b.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppStrings.t(completed ? 'bookAgain' : 'view'),
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: p.textPrimary)),
                  Text(b.whenLabel,
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
            ),
            if (b.status == 'COMPLETED')
              ElevatedButton(
                onPressed: () =>
                    MainShell.of(context)?.openServiceCategory(b.category),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(AppStrings.t('bookAgain'),
                    style: const TextStyle(fontSize: 12)),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    AppStrings.t(b.status == 'REQUESTED' ? 'pending' : 'live'),
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

  Widget _buildEmergencyCompactBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.blueGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.17),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: AppColors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.t('needEmergencyHelp'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _supportPhone,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _callSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primaryBlue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.call_rounded, size: 15),
              label: Text(
                AppStrings.t('callSupport'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t('needEmergencyHelp'),
                  style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(_supportPhone,
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 12)),
            ],
          );
          final action = ElevatedButton.icon(
            onPressed: _callSupport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.call, size: 16),
            label: Text(AppStrings.t('callSupport'),
                style: const TextStyle(fontSize: 12.5)),
          );

          if (constraints.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: action),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
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
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(t.rating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary)),
                      Text(' (${t.ratingCount})',
                          style: TextStyle(
                              fontSize: 11.5, color: p.textSecondary)),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 13, color: p.textSecondary),
                      Expanded(
                        child: Builder(builder: (_) {
                          final km = _distanceKm(t);
                          return Text(
                            km != null
                                ? ' ${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
                                    '${AppStrings.t(AppSettings.instance.distanceUnitKey)}'
                                : ' ${AppStrings.t('locationUnknown')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5, color: p.textSecondary),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppStrings.t(t.available ? 'available' : 'unavailable'),
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
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _sectionHeader(String title,
      {VoidCallback? onSeeAll, bool roundButton = false, String? badge}) {
    final p = context.pal;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary))),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E9E52))),
              ),
            ],
          ],
        )),
        if (onSeeAll != null && roundButton)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onSeeAll,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.primaryBlue),
            ),
          )
        else if (onSeeAll != null)
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
                  _drawerRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Trust & Safety',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showTrustInfo();
                    },
                  ),
                  _drawerRow(
                    icon: Icons.privacy_tip_outlined,
                    label: AppStrings.t('privacyPolicy'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/privacy-policy');
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
                  const SizedBox(height: 8),
                  Center(
                    child: Text('CAMFIX v$_appVersion',
                        style: TextStyle(fontSize: 11, color: p.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Matches pubspec.yaml's version — real, not a placeholder.
  static const String _appVersion = '1.2.8';

  void _showTrustInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trust & Safety'),
        content: const Text(
          'Every technician goes through admin review before they can appear '
          'in the app or take jobs. Ratings you see come only from customers '
          'who completed a real booking with that technician.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppStrings.t('done')),
          ),
        ],
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
    FavoritesApi.instance.clear();
    BookingsStore.instance.clear();
    NotificationsStore.instance.clear();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
