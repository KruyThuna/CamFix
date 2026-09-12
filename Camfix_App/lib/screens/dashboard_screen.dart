import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../models/tracking_info.dart';
import '../services/bookings_store.dart';
import '../services/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'main_shell.dart';
import 'services_screen.dart';
import 'tracking_details_sheet.dart';

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

class _Technician {
  const _Technician(this.name, this.role, this.distance, this.lat, this.lng);
  final String name;
  final String role;
  final String distance;
  final double lat;
  final double lng;
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0; // 0 = Book a service, 1 = Active Job, 2 = History

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

  final _technicians = const [
    _Technician('Rotha Brak', 'Car Repair', '1.6km Nearby', 11.5680, 104.9010),
    _Technician(
        'Chetra Prime', 'Air Conditioner', '2.6km Nearby', 11.5620, 104.8880),
    _Technician('Steven', 'Electrical', '3.2km Nearby', 11.5490, 104.9160),
    _Technician('B Sokha', 'Motorcycle', '3.6km Nearby', 11.5780, 104.9250),
  ];

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
    // Re-evaluate the time-of-day greeting once a minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    CurrentUser.instance.removeListener(_onUser);
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
  void _openTechnician(_Technician t) {
    Navigator.of(context).pushNamed(
      '/provider',
      arguments: ServiceProvider(
        name: t.name,
        category: t.role,
        location: 'Phnom Penh',
        rating: 4.5,
        distanceKm: double.tryParse(t.distance.split('km').first.trim()) ?? 1.6,
        latitude: t.lat,
        longitude: t.lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              // Nearby Technicians / Active / History sit on a white sheet
              // that curves up right below the blue section (mockup p.10).
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.only(top: 20, bottom: 110 + bottomInset),
                child: _buildTabContent(),
              ),
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
                _iconCircle(Icons.menu_rounded, onTap: () {}),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        const UserAvatar(
                            radius: 20, bgColor: AppColors.white),
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
                _iconCircle(Icons.notifications_none_rounded, onTap: () {}),
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
      builder: (context, _) => _tabIndex == 1
          ? _buildActiveJobSection()
          : _buildHistorySection(),
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
          ..._technicians.map(_technicianTile),
        ],
      ),
    );
  }

  Widget _technicianTile(_Technician t) {
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
                Text(t.role,
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
                  Text(t.distance,
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 13, color: AppColors.primaryBlue),
                  const SizedBox(width: 3),
                  Text(AppStrings.t('available'),
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue)),
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
                onTap: () =>
                    showTrackingDetails(context, TrackingInfo.sample),
                title: categoryLabel(b.category),
                subtitle: b.whenLabel,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AppStrings.t('live'),
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
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
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
                          _chipButton(AppStrings.t('ratings'), filled: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _chipButton(String label, {bool filled = true}) {
    return Container(
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
}
