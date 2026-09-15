import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Help & Support screen (reached from Profile): shows the support email and
/// phone number, tappable to open the device's mail app / dialer.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _email = 'camfix098@gmail.com';
  static const String _phone = '+855 879 084 70';

  Future<void> _call(BuildContext context) async {
    final uri = Uri.parse('tel:${_phone.replaceAll(' ', '')}');
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('couldNotCall'))),
      );
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _email);
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('couldNotOpenEmail'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Text(
                AppStrings.t('helpSupportIntro'),
                style: TextStyle(fontSize: 14, color: p.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              _card(context, [
                _contactRow(
                  context,
                  icon: Icons.call_outlined,
                  label: AppStrings.t('callUs'),
                  value: _phone,
                  onTap: () => _call(context),
                ),
                _divider(context),
                _contactRow(
                  context,
                  icon: Icons.email_outlined,
                  label: AppStrings.t('emailUs'),
                  value: _email,
                  onTap: () => _sendEmail(context),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        _circleBackButton(context),
        Expanded(
          child: Center(
            child: Text(
              AppStrings.t('helpAndSupport'),
              style: AppText.h2.copyWith(fontSize: 20, color: p.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _circleBackButton(BuildContext context) {
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

  Widget _card(BuildContext context, List<Widget> children) {
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

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: 56,
        endIndent: 16,
        color: context.pal.border,
      );

  Widget _contactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12.5, color: p.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
