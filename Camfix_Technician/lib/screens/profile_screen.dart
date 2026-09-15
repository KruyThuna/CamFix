import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/technician_profile.dart';
import '../services/current_technician.dart';
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
  final _hours = TextEditingController();
  String _category = kServiceCategories.first;
  bool _editing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fill(CurrentTechnician.instance.value);
  }

  void _fill(TechnicianProfile? p) {
    if (p == null) return;
    _first.text = p.firstName == '-' ? '' : p.firstName;
    _last.text = p.lastName == '-' ? '' : p.lastName;
    _area.text = p.serviceArea;
    _about.text = p.about ?? '';
    _hours.text = p.openingHours ?? '';
    if (kServiceCategories.contains(p.category)) _category = p.category;
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _area, _about, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result =
        await Navigator.of(context).pushNamed('/location-picker');
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
        'openingHours': _hours.text.trim(),
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
                child: Text(AppStrings.t('edit'))),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildAvatar(),
                const SizedBox(height: 20),
                if (!_editing) ...[
                  _langRow(context),
                  const SizedBox(height: 4),
                  _darkRow(context),
                  const Divider(height: 24),
                  _kv(context, AppStrings.t('name'), profile.displayName),
                  _kv(context, AppStrings.t('email'), profile.email),
                  _kv(context, AppStrings.t('phone'), profile.phoneNumber),
                  _kv(context, AppStrings.t('category'),
                      AppStrings.category(profile.category)),
                  _kv(context, AppStrings.t('serviceArea'), profile.serviceArea),
                  _kv(context, AppStrings.t('about'), profile.about ?? '—'),
                  _kv(context, AppStrings.t('openingHours'),
                      profile.openingHours ?? '—'),
                  _kv(context, AppStrings.t('rating'),
                      '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount})'),
                  _kv(context, AppStrings.t('statusLabel'),
                      '${AppStrings.approval(profile.approvalStatus)} · ${AppStrings.account(profile.accountStatus)}'),
                ] else ...[
                  Row(children: [
                    Expanded(
                        child: LabeledField(
                            label: AppStrings.t('firstName'),
                            controller: _first)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: LabeledField(
                            label: AppStrings.t('lastName'),
                            controller: _last)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(AppStrings.t('serviceCategory'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.textSecondary)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _category,
                        items: [
                          for (final c in kServiceCategories)
                            DropdownMenuItem(
                                value: c, child: Text(AppStrings.category(c))),
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
                      )),
                  LabeledField(
                      label: AppStrings.t('about'),
                      controller: _about,
                      maxLines: 3),
                  LabeledField(
                      label: AppStrings.t('openingHours'), controller: _hours),
                  const SizedBox(height: 4),
                  PrimaryButton(
                      label: AppStrings.t('save'),
                      busy: _busy,
                      onPressed: _save),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _editing = false),
                      child: Text(AppStrings.t('cancel')),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildAvatar() {
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
                  child: const Icon(Icons.photo_camera,
                      size: 14, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langRow(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.language, size: 20, color: p.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppStrings.t('language'),
                style: TextStyle(fontSize: 15, color: p.textPrimary)),
          ),
          SegmentedButton<AppLang>(
            style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            segments: const [
              ButtonSegment(value: AppLang.en, label: Text('EN')),
              ButtonSegment(value: AppLang.km, label: Text('ខ្មែរ')),
            ],
            selected: {AppSettings.instance.lang},
            onSelectionChanged: (s) => AppSettings.instance.setLang(s.first),
          ),
        ],
      ),
    );
  }

  Widget _darkRow(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(AppSettings.instance.isDark ? Icons.dark_mode : Icons.light_mode,
              size: 20, color: p.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppStrings.t('darkMode'),
                style: TextStyle(fontSize: 15, color: p.textPrimary)),
          ),
          Switch(
            value: AppSettings.instance.isDark,
            activeThumbColor: AppColors.primaryBlue,
            onChanged: (v) => AppSettings.instance.setDarkMode(v),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: 12, color: p.textSecondary)),
          const SizedBox(height: 2),
          Text(v, style: TextStyle(fontSize: 15, color: p.textPrimary)),
        ],
      ),
    );
  }
}
