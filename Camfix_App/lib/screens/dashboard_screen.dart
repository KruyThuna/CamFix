import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../services/bookings_store.dart';
import '../services/current_user.dart';
import '../services/device_location.dart';
import '../services/notifications_store.dart';
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

  Timer? _clock;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            AppStrings.t('nearbyTechnicians'),
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
    );
  }

  Widget _technicianTile(ServiceProvider t) {
    final p = context.pal;
    return InkWell(
      onTap: () => _openTechnician(t),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: p.textPrimary)),
                  Text(categoryLabel(t.category),
                      style: TextStyle(color: p.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: p.textSecondary),
                    const SizedBox(width: 2),
                    Builder(builder: (_) {
                      final km = _distanceKm(t);
                      return Text(
                          km != null
                              ? '${AppSettings.instance.convertKm(km).toStringAsFixed(1)} '
                                  '${AppStrings.t(AppSettings.instance.distanceUnitKey)} '
                                  '${AppStrings.t('nearby')}'
                              : AppStrings.t('locationUnknown'),
                          style: TextStyle(
                              fontSize: 11.5, color: p.textSecondary));
                    }),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                        t.available
                            ? Icons.verified_rounded
                            : Icons.schedule,
                        size: 13,
                        color: t.available
                            ? AppColors.primaryBlue
                            : p.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                        AppStrings.t(t.available ? 'available' : 'unavailable'),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: t.available
                                ? AppColors.primaryBlue
                                : p.textSecondary)),
                  ],
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
