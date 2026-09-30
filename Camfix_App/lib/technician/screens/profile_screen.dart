import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/tech_job.dart';
import '../models/technician_profile.dart';
import '../services/current_technician.dart';
import '../services/device_location.dart';
import '../services/location_reporter.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with LangAware<ProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _area = TextEditingController();
  final _about = TextEditingController();
  final _customHours = TextEditingController();
  String _category = kServiceCategories.first;
  String? _hoursOption;
  bool _editing = false;
  bool _busy = false;
  bool _togglingAvailability = false;

  List<TechJob>? _jobs;
  bool _loadingJobs = true;
  bool _showHistory = false;

  static const _hoursCustom = 'Custom';

  @override
  void initState() {
    super.initState();
    _fill(CurrentTechnician.instance.value);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loadingJobs = true);
    try {
      final jobs = await TechnicianApi.instance.myJobs();
      if (mounted) setState(() => _jobs = jobs);
    } catch (_) {
      // Best-effort - the activity section just stays empty on failure.
    } finally {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  void _fill(TechnicianProfile? p) {
    if (p == null) return;
    _first.text = p.firstName == '-' ? '' : p.firstName;
    _last.text = p.lastName == '-' ? '' : p.lastName;
    _area.text = p.serviceArea;
    _about.text = p.about ?? '';
    if (kServiceCategories.contains(p.category)) _category = p.category;
    final hours = p.openingHours ?? '';
    if (hours.isEmpty) {
      _hoursOption = null;
      _customHours.text = '';
    } else if (kOpeningHoursOptions.contains(hours)) {
      _hoursOption = hours;
      _customHours.text = '';
    } else {
      _hoursOption = _hoursCustom;
      _customHours.text = hours;
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _area, _about, _customHours]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _setAvailable(bool value) async {
    setState(() => _togglingAvailability = true);
    try {
      final updated = await TechnicianApi.instance.setAvailability(value);
      CurrentTechnician.instance.set(updated);
      if (value) {
        LocationReporter.instance.start();
        // Surface a GPS / permission problem right away (the background
        // reporter just retries silently otherwise).
        final loc = await getCurrentLocation();
        if (!loc.ok && mounted) {
          showError(context, AppStrings.t(loc.errorKey!));
        }
      } else if (!LocationReporter.instance.onActiveJob) {
        LocationReporter.instance.stop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).pushNamed('/location-picker');
    if (result is String && result.isNotEmpty) {
      setState(() => _area.text = result);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final updated = await TechnicianApi.instance.updateProfile({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'category': _category,
        'serviceArea': _area.text.trim(),
        'about': _about.text.trim(),
        'openingHours': _hoursOption == _hoursCustom
            ? _customHours.text.trim()
            : (_hoursOption ?? ''),
      });
      CurrentTechnician.instance.set(updated);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final profile = CurrentTechnician.instance.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('myProfile')),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() {
                _fill(profile);
                _editing = true;
              }),
              child: Text(AppStrings.t('edit')),
            ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                _buildAvatar(profile.available),
                const SizedBox(height: 20),
                if (!_editing) ...[
                  Center(
                    child: Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  if (profile.isApproved) ...[
                    const SizedBox(height: 8),
                    Center(child: _approvedBadge()),
                  ],
                  const SizedBox(height: 20),
                  _card([
                    _kv(context, AppStrings.t('phone'), profile.phoneNumber),
                    _kv(context, AppStrings.t('email'), profile.email),
                    _kv(context, AppStrings.t('serviceArea'),
                        profile.serviceArea),
                  ]),
                  _card([
                    _availabilityRow(context, profile),
                    _darkRow(context),
                    _langRow(context),
                  ]),
                  _card([_myServicesRow(context)]),
                  _card([
                    _kv(
                      context,
                      AppStrings.t('category'),
                      AppStrings.category(profile.category),
                    ),
                    _kv(context, AppStrings.t('about'), profile.about ?? '—'),
                    _kv(
                      context,
                      AppStrings.t('openingHours'),
                      profile.openingHours == null ||
                              profile.openingHours!.isEmpty
                          ? '—'
                          : AppStrings.openingHoursOption(
                              profile.openingHours!,
                            ),
                    ),
                    _kv(
                      context,
                      AppStrings.t('rating'),
                      '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount})',
                    ),
                    _kv(
                      context,
                      AppStrings.t('statusLabel'),
                      '${AppStrings.approval(profile.approvalStatus)} · ${AppStrings.account(profile.accountStatus)}',
                    ),
                  ]),
                  _buildActivitySection(),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: AppStrings.t('firstName'),
                          controller: _first,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: AppStrings.t('lastName'),
                          controller: _last,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(
                      AppStrings.t('serviceCategory'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _category,
                        items: [
                          for (final c in kServiceCategories)
                            DropdownMenuItem(
                              value: c,
                              child: Text(AppStrings.category(c)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: AppStrings.t('serviceArea'),
                    controller: _area,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_outlined),
                      tooltip: AppStrings.t('pickOnMap'),
                      onPressed: _pickLocation,
                    ),
                  ),
                  LabeledField(
                    label: AppStrings.t('about'),
                    controller: _about,
                    maxLines: 3,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(
                      AppStrings.t('openingHours'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _hoursOption,
                        hint: Text(AppStrings.t('openingHours')),
                        items: [
                          for (final o in kOpeningHoursOptions)
                            DropdownMenuItem(
                              value: o,
                              child: Text(AppStrings.openingHoursOption(o)),
                            ),
                          DropdownMenuItem(
                            value: _hoursCustom,
                            child: Text(AppStrings.t('hoursCustom')),
                          ),
                        ],
                        onChanged: (v) => setState(() => _hoursOption = v),
                      ),
                    ),
                  ),
                  if (_hoursOption == _hoursCustom) ...[
                    const SizedBox(height: 14),
                    LabeledField(
                      label: AppStrings.t('hoursCustom'),
                      controller: _customHours,
                    ),
                  ],
                  const SizedBox(height: 4),
                  PrimaryButton(
                    label: AppStrings.t('save'),
                    busy: _busy,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed:
                          _busy ? null : () => setState(() => _editing = false),
                      child: Text(AppStrings.t('cancel')),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildAvatar(bool available) {
    final p = context.pal;
    return Center(
      child: GestureDetector(
        onTap: () => pickProfilePhoto(context),
        child: SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const UserAvatar(radius: 42),
              if (available)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.background, width: 2),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 14,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown only when the admin has actually approved this technician - not a
  /// formal certification, just an honest label for the real approval flag.
  Widget _approvedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined,
              size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 5),
          Text(
            AppStrings.t('approvedTechnicianBadge'),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityRow(BuildContext context, TechnicianProfile? profile) {
    final p = context.pal;
    final available = profile?.available ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _icon(available ? Icons.podcasts : Icons.pause_circle_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              available
                  ? AppStrings.t('onlineSharingLocation')
                  : AppStrings.t('offline'),
              style: TextStyle(fontSize: 15, color: p.textPrimary),
            ),
          ),
          if (_togglingAvailability)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(
              value: available,
              activeThumbColor: AppColors.success,
              onChanged:
                  (profile?.isOperational ?? false) ? _setAvailable : null,
            ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final picked = await showModalBottomSheet<AppLang>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LanguageSheet(),
    );
    if (picked != null) AppSettings.instance.setLang(picked);
  }

  Widget _langRow(BuildContext context) {
    final p = context.pal;
    final current = AppSettings.instance.lang;
    return InkWell(
      onTap: () => _pickLanguage(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _icon(Icons.translate),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.t('language'),
                style: TextStyle(fontSize: 15, color: p.textPrimary),
              ),
            ),
            Text(
              current == AppLang.km
                  ? AppStrings.t('khmer')
                  : AppStrings.t('english'),
              style: TextStyle(fontSize: 14, color: p.textSecondary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 22, color: p.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _myServicesRow(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/service-listings'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _icon(Icons.design_services_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.t('myServices'),
                style: TextStyle(fontSize: 15, color: p.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: p.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _darkRow(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _icon(Icons.dark_mode_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.t('darkMode'),
              style: TextStyle(fontSize: 15, color: p.textPrimary),
            ),
          ),
          Switch(
            value: AppSettings.instance.isDark,
            activeTrackColor: const Color(0xFF3468FF),
            activeThumbColor: Colors.white,
            onChanged: (v) => AppSettings.instance.setDarkMode(v),
          ),
        ],
      ),
    );
  }

  /// "Technician Activity" section - same real jobs HomeScreen shows
  /// (`TechnicianApi.instance.myJobs()`), split into Active/History the
  /// same way (`TechJob.isActive`), not duplicated/fabricated data.
  Widget _buildActivitySection() {
    final p = context.pal;
    final jobs = _jobs ?? const <TechJob>[];
    final active = jobs.where((j) => j.isActive).toList();
    final history = jobs.where((j) => !j.isActive).toList();
    final visible = _showHistory ? history : active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.t('technicianActivity'),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/home'),
              child: Text(AppStrings.t('viewDispatch'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _activityTab(
                      '${AppStrings.t('tabActive')} (${active.length})',
                      !_showHistory,
                      () => setState(() => _showHistory = false))),
              Expanded(
                  child: _activityTab(AppStrings.t('tabHistory'), _showHistory,
                      () => setState(() => _showHistory = true))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingJobs)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (visible.isEmpty)
          _activityEmptyState()
        else
          Column(
            children: [
              for (final j in visible.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _activityJobRow(j),
                ),
            ],
          ),
      ],
    );
  }

  Widget _activityTab(String label, bool active, VoidCallback onTap) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.white : p.textPrimary)),
      ),
    );
  }

  Widget _activityEmptyState() {
    final p = context.pal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.work_outline, color: p.textSecondary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            _showHistory
                ? AppStrings.t('noPastJobs')
                : AppStrings.t('noActiveJobs'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary),
          ),
          if (!_showHistory) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.t('noActiveJobsSubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityJobRow(TechJob j) {
    final p = context.pal;
    return InkWell(
      onTap: () async {
        await Navigator.of(context).pushNamed('/job', arguments: j.id);
        _loadJobs();
      },
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
            _icon(Icons.home_repair_service_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${j.id} · ${j.customerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: p.textPrimary)),
                  Text(AppStrings.category(j.category),
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
            ),
            Text(AppStrings.jobStatus(j.status, selfDrop: j.isSelfDrop),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue)),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    final p = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 62,
                  endIndent: 16,
                  color: p.border,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _icon(IconData icon) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF3468FF).withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF3468FF)),
      );

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    final icons = {
      AppStrings.t('phone'): Icons.phone_outlined,
      AppStrings.t('email'): Icons.mail_outline,
      AppStrings.t('category'): Icons.home_repair_service_outlined,
      AppStrings.t('serviceArea'): Icons.location_on_outlined,
      AppStrings.t('about'): Icons.info_outline,
      AppStrings.t('openingHours'): Icons.schedule,
      AppStrings.t('rating'): Icons.star_outline,
      AppStrings.t('statusLabel'): Icons.verified_user_outlined,
    };
    final editable = [
      'category',
      'serviceArea',
      'about',
      'openingHours',
    ].any((key) => AppStrings.t(key) == k);
    return InkWell(
      onTap: editable
          ? () => setState(() {
                _fill(CurrentTechnician.instance.value);
                _editing = true;
              })
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            _icon(icons[k] ?? Icons.person_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    v,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (editable) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 22, color: p.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing the app language (mirrors the customer app's
/// profile language picker).
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final current = AppSettings.instance.lang;

    Widget option(AppLang lang, String flag, String labelKey) {
      final selected = lang == current;
      return InkWell(
        onTap: () => Navigator.pop(context, lang),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(AppStrings.t(labelKey),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary)),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primaryBlue : p.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(AppStrings.t('language'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
            ),
          ),
          const SizedBox(height: 6),
          option(AppLang.km, '🇰🇭', 'khmer'),
          option(AppLang.en, '🇬🇧', 'english'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
