import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/user_info.dart';
import '../services/current_user.dart';
import '../services/token_store.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

/// Profile screen (mockup pages 22–23): user summary card, quick settings
/// (Dark Mode / Language / Notifications), a secondary settings group and
/// a Logout row. The account rows deep-link to Edit Profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Shown until GET /api/auth/me resolves (or if signed out).
  static const String _fallbackName = 'CAM FIX user';
  static const String _address = 'St, SenSok, PhnomPenh...';

  UserInfo? get _user => CurrentUser.instance.value;
  String get _name => _user?.displayName ?? _fallbackName;
  String get _phone => (_user?.realPhone.isNotEmpty ?? false)
      ? _user!.realPhone
      : AppStrings.t('notSet');
  String get _email => (_user?.email.isNotEmpty ?? false)
      ? _user!.email
      : AppStrings.t('notSet');

  @override
  void initState() {
    super.initState();
    CurrentUser.instance.addListener(_onUser);
    CurrentUser.instance.refresh();
  }

  @override
  void dispose() {
    CurrentUser.instance.removeListener(_onUser);
    super.dispose();
  }

  void _onUser() {
    if (mounted) setState(() {});
  }

  void _openEditProfile() => Navigator.of(context).pushNamed('/edit-profile');

  Future<void> _logout() async {
    await TokenStore.instance.clear();
    CurrentUser.instance.clear();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<AppLang>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LanguageSheet(),
    );
    if (picked != null) {
      AppSettings.instance.setLang(picked);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 132 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildAvatar(),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildAccountCard(),
              const SizedBox(height: 16),
              _buildSettingsCard(),
              const SizedBox(height: 16),
              _buildMoreCard(),
              const SizedBox(height: 16),
              _buildLogoutRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _circleBackButton(),
        Expanded(
          child: Center(
            child: Text(
              AppStrings.t('profile'),
              style: AppText.h2.copyWith(
                fontSize: 20,
                color: context.pal.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 44), // balances the back button
      ],
    );
  }

  Widget _circleBackButton() {
    final p = context.pal;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(Icons.arrow_back, color: p.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildAvatar() {
    final p = context.pal;
    return Center(
      child: GestureDetector(
        onTap: _openEditProfile,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const UserAvatar(radius: 44),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.background, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 11, color: AppColors.white),
                      const SizedBox(width: 3),
                      Text(AppStrings.t('edit'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          )),
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

  Widget _card({required List<Widget> children}) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        indent: 56,
        endIndent: 16,
        color: context.pal.border,
      );

  Widget _buildAccountCard() {
    return _card(
      children: [
        _accountRow(Icons.phone_outlined, AppStrings.t('phone'), _phone),
        _divider(),
        _accountRow(Icons.email_outlined, AppStrings.t('email'), _email),
        _divider(),
        _accountRow(
            Icons.location_on_outlined, AppStrings.t('address'), _address),
      ],
    );
  }

  Widget _accountRow(IconData icon, String label, String value) {
    final p = context.pal;
    return InkWell(
      onTap: _openEditProfile,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBubble(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final p = context.pal;
    return _card(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _iconBubble(Icons.dark_mode_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(AppStrings.t('darkMode'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary)),
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
        ),
        _divider(),
        _navRow(Icons.translate_rounded, AppStrings.t('language'),
            onTap: _pickLanguage),
        _divider(),
        _navRow(Icons.notifications_none_rounded, AppStrings.t('notifications'),
            onTap: () {}),
      ],
    );
  }

  Widget _buildMoreCard() {
    return _card(
      children: [
        _navRow(Icons.tune_rounded, AppStrings.t('preference'), onTap: () {}),
        _divider(),
        _navRow(Icons.privacy_tip_outlined, AppStrings.t('privacyPolicy'),
            onTap: () {}),
        _divider(),
        _navRow(Icons.help_outline_rounded, AppStrings.t('helpAndSupport'),
            onTap: () {}),
      ],
    );
  }

  Widget _buildLogoutRow() {
    return _card(
      children: [
        _navRow(
          Icons.logout_rounded,
          AppStrings.t('logout'),
          color: const Color(0xFFE5484D),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _navRow(
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    final p = context.pal;
    final tint = color ?? p.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _iconBubble(icon, tint: color ?? AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: tint)),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _iconBubble(IconData icon, {Color tint = AppColors.primaryBlue}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

/// Bottom sheet for choosing the app language.
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
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
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
