import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/user_info.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart';
import '../services/current_user.dart';
import '../services/favorites_api.dart';
import '../services/notifications_store.dart';
import '../services/saved_card_store.dart';
import '../services/token_store.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'payment_wallet_screen.dart';
import '../services/app_update_service.dart';

/// Profile screen (mockup pages 22-23 / 44-45): user summary card, real
/// account info, quick settings (Payment / Notifications / Language), a
/// secondary settings group and a Logout row. The account rows deep-link to
/// Edit Profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Shown until GET /api/auth/me resolves (or if signed out).
  static const String _fallbackName = 'CAM FIX user';

  UserInfo? get _user => CurrentUser.instance.value;
  String get _name => _user?.displayName ?? _fallbackName;

  double? _totalSpend;
  int? _favoritesCount;

  @override
  void initState() {
    super.initState();
    CurrentUser.instance.addListener(_onUser);
    CurrentUser.instance.refresh();
    BookingsStore.instance.addListener(_onUser);
    BookingsStore.instance.refresh();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final spend = await BookingsApi.instance.myTotalSpend();
      if (mounted) setState(() => _totalSpend = spend);
    } catch (_) {
      // offline or server hiccup - the tile just shows a dash
    }
    try {
      final favorites = await FavoritesApi.instance.list();
      if (mounted) setState(() => _favoritesCount = favorites.length);
    } catch (_) {}
  }

  @override
  void dispose() {
    CurrentUser.instance.removeListener(_onUser);
    BookingsStore.instance.removeListener(_onUser);
    super.dispose();
  }

  void _onUser() {
    if (mounted) setState(() {});
  }

  void _openEditProfile() => Navigator.of(context).pushNamed('/edit-profile');

  /// What CAMFIX actually does to keep bookings safe - only things the app
  /// really does, plus the privacy policy link (moved here from its own row).
  void _showTrustInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final p = sheetContext.pal;
        Widget point(IconData icon, String key) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppStrings.t(key),
                      style: TextStyle(
                          fontSize: 13.5, height: 1.4, color: p.textPrimary)),
                ),
              ]),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('trustShield'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary)),
                const SizedBox(height: 16),
                point(Icons.verified_user_outlined, 'trustPointReview'),
                point(Icons.star_outline_rounded, 'trustPointRatings'),
                point(Icons.receipt_long_outlined, 'trustPointQuotes'),
                point(Icons.lock_outline_rounded, 'trustPointChat'),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pushNamed('/privacy-policy');
                  },
                  icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                  label: Text(AppStrings.t('privacyPolicy')),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46)),
                ),
              ],
            ),
          ),
        );
      },
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
              _buildStatsRow(),
              const SizedBox(height: 22),
              _sectionLabel(AppStrings.t('accountPreferencesCaps')),
              _buildSettingsCard(),
              const SizedBox(height: 20),
              _sectionLabel(AppStrings.t('supportTrustCaps')),
              _buildMoreCard(),
              const SizedBox(height: 20),
              _buildLogoutRow(),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  AppSettings.instance.hasDefaultAddress
                      ? 'CAMFIX v$_appVersion (Build $_buildNumber)  •  ${AppSettings.instance.defaultAddress}'
                      : 'CAMFIX v$_appVersion (Build $_buildNumber)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Matches pubspec.yaml's version - real, not a placeholder.
  static const String _appVersion = '1.2.8';
  static const String _buildNumber = '16';

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: context.pal.textSecondary)),
      );

  Widget _buildStatsRow() {
    final p = context.pal;
    final completedRepairs = BookingsStore.instance.completed
        .where((b) => b.status == 'COMPLETED')
        .length;

    // One card, three columns split by hairlines, each with a tinted pill.
    Widget tile(String label, String value, String sub, Color tint,
        {VoidCallback? onTap}) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(sub,
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: tint)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget split() => Container(width: 1, height: 52, color: p.border);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          tile(AppStrings.t('statRepairs'), '$completedRepairs',
              AppStrings.t('completedTab'), const Color(0xFF1E9E52)),
          split(),
          tile(
              AppStrings.t('favorites'),
              _favoritesCount == null ? '—' : '$_favoritesCount',
              AppStrings.t('statSaved'),
              AppColors.primaryBlue,
              onTap: () => Navigator.of(context).pushNamed('/favorites')),
          split(),
          tile(
              AppStrings.t('totalSpendTitle'),
              _totalSpend == null
                  ? '—'
                  : '\$${_totalSpend!.toStringAsFixed(0)}',
              AppStrings.t('statAllTime'),
              const Color(0xFF8E44E8),
              onTap: () => Navigator.of(context).pushNamed('/total-spend')),
        ],
      ),
    );
  }

  // A top-level tab (reached via the bottom nav), not a pushed screen - no
  // back arrow, same as Dashboard/Services/Chat's own headers.
  Widget _buildHeader() {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        AppStrings.t('profile'),
        style: AppText.h2.copyWith(fontSize: 22, color: p.textPrimary),
      ),
    );
  }

  Widget _buildAvatar() {
    final p = context.pal;
    return Center(
      child: GestureDetector(
        onTap: _openEditProfile,
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft blue ring around the photo, as in the mockup.
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surface,
                  border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      width: 3),
                ),
                child: const UserAvatar(radius: 44),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.background, width: 2),
                  ),
                  child:
                      const Icon(Icons.edit, size: 13, color: AppColors.white),
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
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, 4)),
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

  Widget _switchRow(IconData icon, Color tint, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _iconBubble(icon, tint: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    final p = context.pal;
    final card = SavedCardStore.instance.card;
    return _card(
      children: [
        _richNavRow(
          Icons.credit_card_rounded,
          AppStrings.t('paymentWallet'),
          card != null
              ? 'Card •••• ${card.last4}'
              : AppStrings.t('noPaymentMethodYet'),
          tint: AppColors.primaryBlue,
          trailing: card != null
              ? Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71), shape: BoxShape.circle),
                )
              : null,
          onTap: () async {
            await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentWalletScreen()));
            if (mounted) setState(() {});
          },
        ),
        _divider(),
        _switchRow(
          Icons.notifications_none_rounded,
          const Color(0xFFB455E0),
          AppStrings.t('pushNotifications'),
          AppStrings.t('notificationsDesc'),
          AppSettings.instance.notificationsEnabled,
          (v) {
            AppSettings.instance.setNotificationsEnabled(v);
            if (v) {
              NotificationsStore.instance.startPolling();
            } else {
              NotificationsStore.instance.stopPolling();
            }
            setState(() {});
          },
        ),
        _divider(),
        _richNavRow(
          Icons.translate_rounded,
          AppStrings.t('appLanguage'),
          AppStrings.t('languageOptionsDesc'),
          tint: const Color(0xFF1E9E52),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
                AppSettings.instance.lang == AppLang.km
                    ? AppStrings.t('khmer')
                    : AppStrings.t('english'),
                style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
          ),
          onTap: _pickLanguage,
        ),
        _divider(),
        _switchRow(
          Icons.dark_mode_outlined,
          const Color(0xFF34495E),
          AppStrings.t('darkMode'),
          AppStrings.t('darkModeDesc'),
          AppSettings.instance.isDark,
          (v) {
            AppSettings.instance.setDarkMode(v);
            setState(() {});
          },
        ),
        _divider(),
        _richNavRow(
          Icons.tune_rounded,
          AppStrings.t('preference'),
          AppStrings.t('preferenceDesc'),
          tint: const Color(0xFFD9822B),
          onTap: () => Navigator.of(context).pushNamed('/preference'),
        ),
      ],
    );
  }

  Widget _buildMoreCard() {
    return _card(
      children: [
        _richNavRow(
          Icons.help_outline_rounded,
          AppStrings.t('helpCenter'),
          AppStrings.t('helpCenterDesc'),
          tint: const Color(0xFF16A085),
          onTap: () => Navigator.of(context).pushNamed('/help-support'),
        ),
        _divider(),
        _richNavRow(
          Icons.handshake_outlined,
          AppStrings.t('trustShield'),
          AppStrings.t('trustShieldDesc'),
          tint: AppColors.primaryBlue,
          onTap: _showTrustInfo,
        ),
        _divider(),
        _richNavRow(
          Icons.system_update_rounded,
          AppStrings.t('appUpdateTitle'),
          AppStrings.t('appUpdateSubtitle'),
          tint: const Color(0xFFE67E22),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'v${AppUpdateService.currentVersion}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.pal.textSecondary,
              ),
            ),
          ),
          onTap: () => AppUpdateService.instance
              .checkForUpdate(context, silent: false),
        ),
      ],
    );
  }

  Widget _richNavRow(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    Widget? trailing,
    Color tint = AppColors.primaryBlue,
  }) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBubble(icon, tint: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutRow() {
    const red = Color(0xFFE5484D);
    return InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: red.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 18, color: red),
            const SizedBox(width: 8),
            Text(AppStrings.t('logout'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: red)),
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
          option(AppLang.km, '\u{1F1F0}\u{1F1ED}', 'khmer'),
          option(AppLang.en, '\u{1F1EC}\u{1F1E7}', 'english'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
