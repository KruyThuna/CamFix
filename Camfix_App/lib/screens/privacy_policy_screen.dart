import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Privacy Policy screen (reached from Profile): a plain-language summary of
/// what CAM FIX collects and how it's used - not a formal legal document.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _buildHeader(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.t('privacyIntro'),
                        style: TextStyle(
                            fontSize: 13.5, color: p.textSecondary, height: 1.5)),
                    const SizedBox(height: 20),
                    _section(context, AppStrings.t('privacyCollectTitle'),
                        AppStrings.t('privacyCollectBody')),
                    _section(context, AppStrings.t('privacyUseTitle'),
                        AppStrings.t('privacyUseBody')),
                    _section(context, AppStrings.t('privacySharingTitle'),
                        AppStrings.t('privacySharingBody')),
                    _section(context, AppStrings.t('privacyChoicesTitle'),
                        AppStrings.t('privacyChoicesBody')),
                    _section(context, AppStrings.t('privacyContactTitle'),
                        AppStrings.t('privacyContactBody')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(fontSize: 13.5, color: p.textSecondary, height: 1.5)),
        ],
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
              AppStrings.t('privacyPolicy'),
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
}
