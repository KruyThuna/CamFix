import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../models/service_provider.dart';
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

/// A skill line on the Achievements tab: an icon, the skill name and how many
/// of that job the provider has completed.
class _Skill {
  const _Skill(this.icon, this.label, this.count);
  final IconData icon;
  final String label;
  final int count;
}

/// A bookable service package shown under "Service" on the Achievements tab.
class _ServiceOffer {
  const _ServiceOffer({
    required this.title,
    required this.price,
    required this.duration,
    required this.bullets,
  });
  final String title;
  final String price;
  final String duration;
  final List<String> bullets;
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

  static const int _jobsCompleted = 105;

  static const List<_Skill> _skills = [
    _Skill(Icons.build_rounded, 'Air Conditioner Repair', 57),
    _Skill(Icons.cleaning_services_rounded, 'Air Conditioner Clean', 25),
    _Skill(Icons.handyman_rounded, 'Air Conditioner Installation', 23),
  ];

  static const List<_ServiceOffer> _offers = [
    _ServiceOffer(
      title: 'Air Conditioner Repair',
      price: 'USD 20+',
      duration: '1h - 2h',
      bullets: [
        'Refrigerant Check',
        'Compressor Diagnosis',
        'Electrical Troubleshooting',
        'Pressure Testing',
      ],
    ),
    _ServiceOffer(
      title: 'Air Conditioner Clean',
      price: 'USD 20+',
      duration: '40 min+',
      bullets: ['Filter Cleaning', 'Coil Cleaning', 'Drainage Cleaning'],
    ),
    _ServiceOffer(
      title: 'Air Conditioner Installation',
      price: 'USD 40+',
      duration: '2 h +',
      bullets: ['Medium - High', 'Warranty 7 - 30 Days'],
    ),
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

  /// Open a chat thread with this technician.
  void _openChat(ServiceProvider p) {
    Navigator.of(context).pushNamed(
      '/chat-thread',
      arguments: ChatContact(
        name: p.name,
        lastMessage: '',
        time: '',
        online: p.available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        ModalRoute.of(context)?.settings.arguments as ServiceProvider? ??
            _fallback;
    final distance = _fmt(provider.distanceKm);

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

  // --- Header -------------------------------------------------------------

  Widget _buildHeader(ServiceProvider p, String distance) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(Icons.arrow_back,
                    color: _text, size: 22),
              ),
            ),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 44,
              backgroundColor: _alt,
              child: const Icon(Icons.person, size: 46, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
              decoration: BoxDecoration(
                color: (p.available ? _green : _muted).withValues(alpha: 0.14),
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
            const SizedBox(height: 6),
            Text(p.name,
                style: AppText.h2.copyWith(fontSize: 20, color: _text)),
            const SizedBox(height: 3),
            Text(
              '${categoryLabel(p.category)}  |  ${_roleLabel(p.role)}',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 3),
                Text('${distance}km ${AppStrings.t('nearby')}',
                    style: TextStyle(
                        fontSize: 12.5, color: _text)),
                const SizedBox(width: 14),
                const Icon(Icons.call, size: 13, color: AppColors.primaryBlue),
                const SizedBox(width: 3),
                Text(p.phone,
                    style: TextStyle(
                        fontSize: 12.5, color: _text)),
              ],
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
        children: List.generate(_tabs.length, (i) {
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
                      AppStrings.t(_tabKeys[i]),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.primaryBlue : _muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 2.5,
                      width: 24,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
        Text(p.openingHours,
            style: TextStyle(fontSize: 13, color: _muted)),
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
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _text),
            ),
            _starRow(p.rating, size: 15),
            const SizedBox(height: 4),
            Text('${p.ratingCount} ${AppStrings.t('ratingCountSuffix')}',
                style:
                    TextStyle(fontSize: 11.5, color: _muted)),
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
                        style: TextStyle(
                            fontSize: 11, color: _muted)),
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
                          style: TextStyle(
                              fontSize: 11, color: _muted)),
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
                  interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none),
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
        label: Text('${AppStrings.t('getDirection')}   ·   $distance km'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          textStyle: AppText.button.copyWith(fontSize: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // --- Achievements tab ----------------------------------------------------

  Widget _buildAchievementsTab(ServiceProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${categoryLabel(p.category)} ${_roleLabel(p.role)}',
            style:
                const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._skills.map(_skillPill),
        const SizedBox(height: 18),
        _sectionTitle(AppStrings.t('service')),
        const SizedBox(height: 12),
        _buildServiceHeader(p),
        const SizedBox(height: 16),
        ..._offers.map((o) => _offerCard(p, o)),
      ],
    );
  }

  Widget _skillPill(_Skill s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _alt, shape: BoxShape.circle),
            child: Icon(s.icon, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(s.label,
                style:
                    TextStyle(fontSize: 13, color: _text)),
          ),
          Text('${s.count}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _text)),
        ],
      ),
    );
  }

  Widget _buildServiceHeader(ServiceProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 150,
            width: double.infinity,
            color: _placeholderGrey,
            child: Icon(Icons.ac_unit_rounded,
                size: 56, color: _muted.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(height: 10),
        Text(categoryLabel(p.category),
            style: AppText.h2.copyWith(fontSize: 18, color: _text)),
        const SizedBox(height: 4),
        Row(
          children: [
            _starRow(4, size: 14),
            const SizedBox(width: 6),
            Text('$_jobsCompleted ${AppStrings.t('jobCompletedSuffix')}',
                style: TextStyle(fontSize: 12, color: _muted)),
          ],
        ),
      ],
    );
  }

  Widget _offerCard(ServiceProvider p, _ServiceOffer o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ac_unit_rounded, size: 13, color: _green),
                const SizedBox(width: 4),
                Text(categoryLabel(p.category),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _green)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _placeholderGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.ac_unit_rounded,
                    size: 24, color: _muted.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(o.price,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: _green),
              const SizedBox(width: 4),
              Text(o.duration,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _green)),
            ],
          ),
          const SizedBox(height: 8),
          ...o.bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.primaryBlue)),
                  Expanded(
                    child: Text(b,
                        style: TextStyle(
                            fontSize: 12.5, color: _muted)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () => showBookingSheet(context, p),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStrings.t('booking')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reviews tab ------------------------------------------------------------

  Widget _buildReviewsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._reviews.map(_reviewCard),
      ],
    );
  }

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
                child:
                    const Icon(Icons.person, size: 20, color: AppColors.primaryBlue),
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
                        style: TextStyle(
                            fontSize: 11.5, color: _muted)),
                  ],
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _snack(AppStrings.t('reviewOptions')),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.more_vert,
                      size: 18, color: _muted),
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
              Text(r.date,
                  style: TextStyle(
                      fontSize: 11.5, color: _muted)),
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
              style: TextStyle(
                  fontSize: 13, color: _text, height: 1.4)),
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
              style:
                  TextStyle(fontSize: 11.5, color: _muted)),
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
                child:
                    const Icon(Icons.person, size: 14, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Text(reply.name,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('· ${reply.date}',
                  style:
                      TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(reply.text,
              style: TextStyle(
                  fontSize: 12, color: _muted, height: 1.4)),
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
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: _text),
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
