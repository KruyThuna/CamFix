import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../services/chat_api.dart';
import '../models/review.dart';
import '../models/service_provider.dart';
import '../models/technician_service_listing.dart';
import '../services/api_client.dart';
import '../services/device_location.dart';
import '../services/favorites_api.dart';
import '../services/service_prices_api.dart';
import '../services/technicians_api.dart';
import '../theme/app_theme.dart';
import 'booking_sheet.dart';
import 'services_screen.dart' show categoryLabel;

/// Provider detail screen (mockup page 16): avatar + status, contact actions,
/// an Info / Achievements / Reviews tab switcher, rating breakdown,
/// about / hours / address, a map preview and a "Get Direction" action.
class ProviderDetailScreen extends StatefulWidget {
  const ProviderDetailScreen({super.key});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

/// The provider's reply underneath a customer review.
class _Reply {
  const _Reply(this.name, this.date, this.text);
  final String name;
  final String date;
  final String text;
}

class _Review {
  const _Review({
    required this.name,
    required this.reviewsCount,
    required this.rating,
    required this.date,
    required this.text,
    required this.orderedService,
    this.withPhoto = false,
    this.reply,
  });

  final String name;
  final int reviewsCount;
  final double rating;
  final String date;
  final String text;
  final String orderedService;
  final bool withPhoto;
  final _Reply? reply;
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  static const Color _amber = Color(0xFFFFB300);
  static const Color _green = Color(0xFF2ECC71);

  // Theme-aware surface / text / border colors.
  AppPalette get _p => context.pal;
  Color get _surface => _p.surface;
  Color get _bg => _p.background;
  Color get _text => _p.textPrimary;
  Color get _muted => _p.textSecondary;
  Color get _alt => _p.surfaceAlt;
  Color get _line => _p.border;
  Color get _placeholderGrey => _p.surfaceAlt;

  static const ServiceProvider _fallback = ServiceProvider(
    name: 'Vanna Sok',
    category: 'Air Conditioner',
    location: 'SenSok, PhnomPenh',
    rating: 4.5,
    latitude: 11.5872,
    longitude: 104.8951,
  );

  static const List<String> _tabs = ['Info', 'Achievements', 'Reviews'];
  static const List<String> _tabKeys = [
    'tabInfo',
    'tabAchievements',
    'tabReviews',
  ];

  static const List<_Review> _reviews = [
    _Review(
      name: 'Sakana ABC',
      reviewsCount: 2,
      rating: 4,
      date: '09 June 2025',
      text: 'he do the work so fast also good quality, thanks',
      orderedService: 'Air Conditioner clean',
      withPhoto: true,
      reply: _Reply('Vanna Sok', '10 June 2025', 'Thank you bong for reviews'),
    ),
    _Review(
      name: 'Sakana ABC',
      reviewsCount: 2,
      rating: 4,
      date: '09 June 2025',
      text: 'he do the work so fast also good quality, thanks',
      orderedService: 'Air Conditioner clean',
      withPhoto: true,
      reply: _Reply('Vanna Sok', '10 June 2025', 'Thank you bong for reviews'),
    ),
  ];

  int _tabIndex = 0;

  int? _technicianId;
  List<Review> _realReviews = const [];
  bool _loadingReviews = false;
  List<TechnicianServiceListing> _services = const [];
  bool _loadingServices = false;

  /// The listing picked on the Achievements tab (one per booking).
  int? _selectedListingId;

  TechnicianServiceListing? get _selectedListing {
    for (final l in _services) {
      if (l.id == _selectedListingId) return l;
    }
    return null;
  }

  bool? _isFavorite;
  bool _favoriteBusy = false;

  /// Freshly fetched on open so edits the technician made after the calling
  /// screen's list was loaded (dashboard/services - which can stay alive in
  /// memory for a long time) still show up here instead of stale nav-arg data.
  ServiceProvider? _freshProvider;

  /// Real "starting from" price for this technician's whole category (the
  /// same catalog price shown elsewhere in the app) - there's no real
  /// per-sub-service pricing to show instead.
  double? _startingPrice;
  bool _didInit = false;

  /// Customer's GPS fix for the real distance to this technician.
  LatLng? _myPos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments as ServiceProvider?;
    if (!_didInit) {
      _didInit = true;
      getCurrentLocation().then((fix) {
        if (mounted && fix.ok) {
          setState(() =>
              _myPos = LatLng(fix.position!.latitude, fix.position!.longitude));
        }
      });
      ServicePricesApi.instance
          .startingPriceFor((arg ?? _fallback).category)
          .then((price) {
        if (mounted) setState(() => _startingPrice = price);
      });
    }
    if (_technicianId != null) return;
    final id = (arg ?? _fallback).technicianId;
    if (id == null) return;
    _technicianId = id;
    _loadProvider(id);
    _loadReviews(id);
    _loadFavoriteStatus(id);
    _loadServices(id);
  }

  Future<void> _loadServices(int technicianId) async {
    setState(() => _loadingServices = true);
    try {
      final services = await TechniciansApi.instance.services(technicianId);
      if (mounted) setState(() => _services = services);
    } catch (_) {
      // Real listings are a nice-to-have on this tab; fail quietly.
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadProvider(int technicianId) async {
    try {
      final fresh = await TechniciansApi.instance.get(technicianId);
      if (mounted) setState(() => _freshProvider = fresh);
    } catch (_) {
      // Fall back to whatever the calling screen passed in.
    }
  }

  Future<void> _loadReviews(int technicianId) async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await TechniciansApi.instance.reviews(technicianId);
      if (mounted) setState(() => _realReviews = reviews);
    } catch (_) {
      // real reviews are a nice-to-have on this screen; fail quietly
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadFavoriteStatus(int technicianId) async {
    try {
      final fav = await FavoritesApi.instance.check(technicianId);
      if (mounted) setState(() => _isFavorite = fav);
    } catch (_) {
      // favorite status is a nice-to-have; fail quietly
    }
  }

  Future<void> _toggleFavorite() async {
    final id = _technicianId;
    if (id == null) return;
    final current = _isFavorite ?? false;
    setState(() {
      _isFavorite = !current;
      _favoriteBusy = true;
    });
    try {
      if (current) {
        await FavoritesApi.instance.remove(id);
      } else {
        await FavoritesApi.instance.add(id);
      }
      if (mounted) {
        _snack(AppStrings.t(
            current ? 'removedFromFavorites' : 'addedToFavorites'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = current);
        _snack(e.toString());
      }
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  /// Drops a trailing ".0" so 4.0 shows as "4" but 4.5 stays "4.5".
  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  /// Localised job role ("Professional" is the only value in the sample data).
  static String _roleLabel(String role) =>
      role == 'Professional' ? AppStrings.t('roleProfessional') : role;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  /// Open the in-app directions map to this technician's shop — a real
  /// road route the customer can follow to go check the repair. That screen
  /// also offers a hand-off to the device's Google Maps for turn-by-turn.
  void _openDirections(ServiceProvider p) {
    Navigator.of(context).pushNamed('/directions', arguments: p);
  }

  /// Chat is per booking: open the conversation for this customer's most
  /// recent booking with this technician, or explain that booking comes
  /// first (there's nobody on the other end until a job exists).
  Future<void> _openChat(ServiceProvider p) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    List<ChatThread> threads;
    try {
      threads = await ChatApi.instance.threads();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    ChatThread? match;
    for (final t in threads) {
      if (p.technicianId != null && t.otherTechnicianId == p.technicianId) {
        if (match == null || t.jobId > match.jobId) match = t;
      }
    }
    if (match == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(AppStrings.t('chatNeedsBooking'))));
      return;
    }
    navigator.pushNamed('/chat-thread',
        arguments: ChatThreadArgs.fromThread(match));
  }

  @override
  Widget build(BuildContext context) {
    final provider = _freshProvider ??
        (ModalRoute.of(context)?.settings.arguments as ServiceProvider? ??
            _fallback);
    // Real GPS distance only - the model's default distance is a
    // placeholder, so show nothing rather than a made-up number.
    final km = _myPos != null && provider.hasLocation
        ? distanceKmBetween(_myPos!.latitude, _myPos!.longitude,
            provider.latitude, provider.longitude)
        : null;
    final distance = km == null
        ? ''
        : '${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
            '${AppStrings.t(AppSettings.instance.distanceUnitKey)}';

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(provider, distance),
                  _buildPanel(provider, distance),
                ],
              ),
            ),
          ),
          _buildBookBar(provider),
        ],
      ),
    );
  }

  Widget _buildBookBar(ServiceProvider p) {
    final picked = _selectedListing;
    if (picked != null) return _buildSelectedBar(p, picked);
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
              color: _p.shadow, blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => showBookingSheet(context, p),
              icon: const Icon(Icons.event_available_rounded, size: 20),
              label: Text(AppStrings.t('bookNow')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                textStyle: AppText.button.copyWith(fontSize: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom bar once a service is picked: "1 selected · Name", its real
  /// starting price, and Continue -> the booking sheet for that listing.
  Widget _buildSelectedBar(ServiceProvider p, TechnicianServiceListing l) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
              color: _p.shadow, blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const CircleAvatar(radius: 4, backgroundColor: _green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    '1 ${AppStrings.t('selectedWord').toLowerCase()} • ${p.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: _text)),
              ),
              Text(
                  '${AppStrings.t('estWord')} \$${l.price.toStringAsFixed(l.price == l.price.roundToDouble() ? 0 : 2)}+',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => showBookingSheet(context, p, listing: l),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  textStyle: AppText.button.copyWith(fontSize: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(AppStrings.t('continueWithSelected')),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // --- Header -------------------------------------------------------------

  Widget _buildHeader(ServiceProvider p, String distance) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(Icons.arrow_back, color: _text, size: 22),
                ),
                const Spacer(),
                if (p.technicianId != null)
                  IconButton(
                    onPressed: _favoriteBusy ? null : _toggleFavorite,
                    tooltip: AppStrings.t('saveTechnicianTooltip'),
                    icon: Icon(
                      _isFavorite == true
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color:
                          _isFavorite == true ? const Color(0xFFE5484D) : _text,
                      size: 22,
                    ),
                  ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                  icon: Icon(Icons.notifications_none_rounded,
                      color: _text, size: 22),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => Navigator.of(context).pushNamed('/profile'),
                  icon: Icon(Icons.person_outline, color: _text, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
                        decoration: BoxDecoration(
                          color: (p.available ? _green : _muted)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.available
                                  ? Icons.how_to_reg_rounded
                                  : Icons.schedule_rounded,
                              size: 15,
                              color: p.available ? _green : _muted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              p.available
                                  ? AppStrings.t('available')
                                  : AppStrings.t('unavailable'),
                              style: TextStyle(
                                color: p.available ? _green : _muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${categoryLabel(p.category)}  |  ${_roleLabel(p.role)}',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      if (distance.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: AppColors.primaryBlue),
                            const SizedBox(width: 3),
                            Text('$distance ${AppStrings.t('nearby')}',
                                style: TextStyle(fontSize: 12.5, color: _text)),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.call,
                              size: 13, color: AppColors.primaryBlue),
                          const SizedBox(width: 3),
                          Text(p.phone,
                              style: TextStyle(fontSize: 12.5, color: _text)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _alt,
                  backgroundImage: (p.photoUrl?.isNotEmpty ?? false)
                      ? CachedNetworkImageProvider(
                          '${ApiClient.instance.baseUrl}${p.photoUrl}')
                      : null,
                  child: (p.photoUrl?.isNotEmpty ?? false)
                      ? null
                      : const Icon(Icons.person,
                          size: 42, color: AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(p.name,
                  style: AppText.h2.copyWith(fontSize: 20, color: _text)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(p),
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                    label: Text(AppStrings.t('messageBtn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _snack('${AppStrings.t('calling')} ${p.phone}…'),
                    icon: const Icon(Icons.call_outlined, size: 19),
                    label: Text(AppStrings.t('audioBtn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _surface,
                      foregroundColor: _text,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      side: BorderSide(color: _line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Panel (tabs + content) ------------------------------------------------

  Widget _buildPanel(ServiceProvider p, String distance) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabBar(),
          const SizedBox(height: 18),
          if (_tabIndex == 0)
            _buildInfoTab(p, distance)
          else if (_tabIndex == 1)
            _buildAchievementsTab(p)
          else
            _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++) ...[
            // Thin separators between tabs, as in the mockup.
            if (i > 0) Container(width: 1, height: 22, color: _line),
            _tabButton(i),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(int i) {
    final bool active = i == _tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = i),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active
                    ? AppStrings.t(_tabKeys[i]).toUpperCase()
                    : AppStrings.t(_tabKeys[i]),
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: active ? 0.4 : 0,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primaryBlue : _muted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 2.5,
                width: 24,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Info tab ------------------------------------------------------------

  Widget _buildInfoTab(ServiceProvider p, String distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.t('rating')),
        const SizedBox(height: 10),
        _buildRatingBlock(p),
        const SizedBox(height: 22),
        _sectionTitle(AppStrings.t('about')),
        const SizedBox(height: 8),
        Text(
          p.about,
          style: TextStyle(fontSize: 13, color: _muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        _subLabel(AppStrings.t('openingHours')),
        const SizedBox(height: 4),
        Text(p.openingHours, style: TextStyle(fontSize: 13, color: _muted)),
        const SizedBox(height: 14),
        _subLabel(AppStrings.t('address')),
        const SizedBox(height: 4),
        Text(
          p.address,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: _muted, height: 1.5),
        ),
        const SizedBox(height: 14),
        _buildMapPreview(p),
        const SizedBox(height: 16),
        _getDirectionButton(p, distance),
      ],
    );
  }

  Widget _buildRatingBlock(ServiceProvider p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              _fmt(p.rating),
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, color: _text),
            ),
            _starRow(p.rating, size: 15),
            const SizedBox(height: 4),
            Text('${p.ratingCount} ${AppStrings.t('ratingCountSuffix')}',
                style: TextStyle(fontSize: 11.5, color: _muted)),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final pct =
                  (i < p.ratingBreakdown.length) ? p.ratingBreakdown[i] : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Text('$star',
                        style: TextStyle(fontSize: 11, color: _muted)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: _placeholderGrey,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_amber),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Text('$pct%',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, color: _muted)),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(ServiceProvider p) {
    final pos = LatLng(p.latitude, p.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: pos,
                  initialZoom: 15,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.camfix_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pos,
                        width: 44,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child: _mapMarker(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () => _openDirections(p)),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _p.shadow, blurRadius: 6)],
                ),
                child: Text(
                  AppStrings.t('tapForDirections'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapMarker() {
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
          child: const Icon(Icons.person, color: AppColors.white, size: 18),
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

  Widget _getDirectionButton(ServiceProvider p, String distance) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openDirections(p),
        icon: const Icon(Icons.near_me_rounded, size: 20),
        label: Text(distance.isEmpty
            ? AppStrings.t('getDirection')
            : '${AppStrings.t('getDirection')}   ·   $distance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          textStyle: AppText.button.copyWith(fontSize: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // --- Achievements tab ----------------------------------------------------

  /// Icon for one listing, guessed from its own title (repair / clean /
  /// install...), falling back to the category icon.
  IconData _listingIcon(String title, String category) {
    final t = title.toLowerCase();
    if (t.contains('clean') || t.contains('wash')) {
      return Icons.cleaning_services_rounded;
    }
    if (t.contains('install') || t.contains('setup') || t.contains('set up')) {
      return Icons.settings_input_component_rounded;
    }
    if (t.contains('repair') || t.contains('fix')) {
      return Icons.construction_rounded;
    }
    if (t.contains('check') || t.contains('inspect') || t.contains('diagnos')) {
      return Icons.fact_check_outlined;
    }
    if (t.contains('tire') || t.contains('tyre') || t.contains('wheel')) {
      return Icons.tire_repair_rounded;
    }
    if (t.contains('oil')) return Icons.oil_barrel_outlined;
    if (t.contains('tune') || t.contains('service') || t.contains('maint')) {
      return Icons.build_circle_outlined;
    }
    if (t.contains('battery')) return Icons.battery_charging_full_rounded;
    if (t.contains('wir') || t.contains('electric') || t.contains('circuit')) {
      return Icons.electrical_services_rounded;
    }
    if (t.contains('pipe') || t.contains('leak') || t.contains('drain')) {
      return Icons.plumbing_rounded;
    }
    return _categoryIcon(category);
  }

  static String _usd(double v) =>
      'USD ${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}+';

  Widget _buildAchievementsTab(ServiceProvider p) {
    final jobs = p.completedJobCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${categoryLabel(p.category)} ${_roleLabel(p.role)}',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: _text)),
        const SizedBox(height: 12),
        if (_services.isNotEmpty)
          // At-a-glance: each real listing + its real completed count.
          for (final listing in _services) _skillPill(p, listing),
        const SizedBox(height: 12),
        _sectionTitle(AppStrings.t('service')),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 170,
            width: double.infinity,
            color: _placeholderGrey,
            child: (p.bannerUrl?.isNotEmpty ?? false)
                ? CachedNetworkImage(
                    imageUrl: '${ApiClient.instance.baseUrl}${p.bannerUrl}',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(_categoryIcon(p.category),
                        size: 52, color: _muted.withValues(alpha: 0.5)),
                  )
                : Icon(_categoryIcon(p.category),
                    size: 52, color: _muted.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(height: 14),
        Text(categoryLabel(p.category),
            style: AppText.h2.copyWith(fontSize: 20, color: _text)),
        const SizedBox(height: 6),
        Row(children: [
          _starRow(p.rating, size: 20),
          if (p.ratingCount > 0) ...[
            const SizedBox(width: 8),
            Text('${_fmt(p.rating)} (${p.ratingCount})',
                style: TextStyle(fontSize: 12, color: _muted)),
          ],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.check_rounded,
                size: 15, color: AppColors.white),
          ),
          const SizedBox(width: 8),
          Text(
              jobs > 0
                  ? '$jobs ${AppStrings.t('jobCompletedSuffix')}'
                  : AppStrings.t('noJobsCompletedYet'),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
        ]),
        const SizedBox(height: 16),
        if (_loadingServices)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_services.isEmpty)
          _buildServiceCard(p)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 236,
            ),
            itemBuilder: (context, i) => _buildListingCard(p, _services[i]),
          ),
      ],
    );
  }

  /// Glowing pill: one real listing and its real completed-job count.
  Widget _skillPill(ServiceProvider p, TechnicianServiceListing listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.16),
              blurRadius: 14,
              spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Icon(_listingIcon(listing.title, p.category),
              color: AppColors.primaryBlue, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: _muted)),
              const SizedBox(height: 1),
              Text('${listing.completedJobCount}',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: _text)),
            ]),
          ),
        ],
      ),
    );
  }

  /// One of the technician's own real listings. Tapping selects it (one at a
  /// time - a booking is for one service); the bottom bar then books it.
  Widget _buildListingCard(
      ServiceProvider p, TechnicianServiceListing listing) {
    final selected = _selectedListingId == listing.id;
    // The listing's own photo; otherwise an icon (not the same technician
    // picture repeated on every card).
    final photo = listing.photoUrl;
    void select() =>
        setState(() => _selectedListingId = selected ? null : listing.id);
    return GestureDetector(
      onTap: select,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.primaryBlue : _line,
              width: selected ? 1.8 : 1),
          boxShadow: [
            BoxShadow(
                color: _p.shadow, blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_categoryIcon(p.category), size: 11, color: _green),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(categoryLabel(p.category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primaryBlue : Colors.transparent,
                  border: Border.all(
                      color: selected ? AppColors.primaryBlue : _muted,
                      width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: AppColors.white)
                    : null,
              ),
            ]),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  color: _placeholderGrey,
                  child: photo != null
                      ? CachedNetworkImage(
                          imageUrl: '${ApiClient.instance.baseUrl}$photo',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                              _listingIcon(listing.title, p.category),
                              size: 20,
                              color: _muted),
                        )
                      : Icon(_listingIcon(listing.title, p.category),
                          size: 20, color: _muted),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: _text)),
                      const SizedBox(height: 3),
                      Text(_usd(listing.price),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _green)),
                      if (listing.completedJobCount > 0)
                        Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: _green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                                '${listing.completedJobCount} ${AppStrings.t('doneWord')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 9.5, color: _muted)),
                          ),
                        ]),
                    ]),
              ),
            ]),
            const SizedBox(height: 8),
            for (final feature in listing.features.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 5),
                      child: CircleAvatar(
                          radius: 2.2, backgroundColor: AppColors.primaryBlue),
                    ),
                    Expanded(
                      child: Text(feature,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, color: _muted)),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Divider(height: 12, color: _line),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 26,
                child: FilledButton(
                  onPressed: select,
                  style: FilledButton.styleFrom(
                    backgroundColor: selected ? _green : AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(selected
                      ? '✓ ${AppStrings.t('selectedWord')}'
                      : '+ ${AppStrings.t('bookingWord')}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceProvider p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _p.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _startingPrice == null
                ? AppStrings.t('personalizedService')
                : '${AppStrings.t('startingAt')} \$${_startingPrice!.toStringAsFixed(_startingPrice == _startingPrice!.roundToDouble() ? 0 : 2)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showBookingSheet(context, p),
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: Text(AppStrings.t('bookNow')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
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

  // --- Reviews tab ------------------------------------------------------------

  Widget _buildReviewsTab() {
    if (_technicianId == null) {
      // No real technician id (a still-mock entry elsewhere in the app) -
      // fall back to the illustrative sample reviews.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._reviews.map(_reviewCard),
        ],
      );
    }
    if (_loadingReviews) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_realReviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(AppStrings.t('noReviewsYet'),
              style: TextStyle(color: _muted)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._realReviews.map(_realReviewCard),
      ],
    );
  }

  Widget _realReviewCard(Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _alt,
                child: const Icon(Icons.person,
                    size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.customerName ?? AppStrings.t('camfixUser'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              if (r.createdAt != null)
                Text(_dateLabel(r.createdAt!),
                    style: TextStyle(fontSize: 11.5, color: _muted)),
            ],
          ),
          const SizedBox(height: 8),
          _starRow(r.rating.toDouble(), size: 14),
          if ((r.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.comment!,
                style: TextStyle(fontSize: 13, color: _text, height: 1.4)),
          ],
        ],
      ),
    );
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  Widget _reviewCard(_Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _alt,
                child: const Icon(Icons.person,
                    size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${r.reviewsCount} ${AppStrings.t('reviewsSuffix')}',
                        style: TextStyle(fontSize: 11.5, color: _muted)),
                  ],
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _snack(AppStrings.t('reviewOptions')),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.more_vert, size: 18, color: _muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _starRow(r.rating, size: 14),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: _line,
              ),
              const SizedBox(width: 8),
              Text(r.date, style: TextStyle(fontSize: 11.5, color: _muted)),
            ],
          ),
          const SizedBox(height: 10),
          if (r.withPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                color: _placeholderGrey,
                child: Icon(Icons.image_outlined,
                    size: 48, color: _muted.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(r.text,
              style: TextStyle(fontSize: 13, color: _text, height: 1.4)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _snack(AppStrings.t('translatingReview')),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate,
                    size: 13, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text(AppStrings.t('seeTranslation'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('${AppStrings.t('orderedPrefix')}${r.orderedService}',
              style: TextStyle(fontSize: 11.5, color: _muted)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _snack(AppStrings.t('reviewLiked')),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_up_alt_outlined, size: 15, color: _muted),
                const SizedBox(width: 6),
                Text(AppStrings.t('like'),
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _muted)),
              ],
            ),
          ),
          if (r.reply != null) ...[
            const SizedBox(height: 12),
            _replyBlock(r.reply!),
          ],
        ],
      ),
    );
  }

  Widget _replyBlock(_Reply reply) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _alt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _surface,
                child: const Icon(Icons.person,
                    size: 14, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Text(reply.name,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('· ${reply.date}',
                  style: TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(reply.text,
              style: TextStyle(fontSize: 12, color: _muted, height: 1.4)),
        ],
      ),
    );
  }

  // --- Shared bits ------------------------------------------------------------

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );

  Widget _subLabel(String text) => Text(
        text,
        style:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text),
      );

  Widget _starRow(double rating, {required double size}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (rating >= i + 1) {
          icon = Icons.star_rounded;
        } else if (rating >= i + 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: size, color: _amber);
      }),
    );
  }
}
