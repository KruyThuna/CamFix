import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late AppLang _selected = AppSettings.instance.lang;

  void _continue() {
    AppSettings.instance.setLang(_selected);
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Text(
                'ជ្រើសរើសភាសា',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text(
                'Choose language',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: BoxDecoration(
                  color: p.background,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LanguageTile(
                      flagEmoji: '🇰🇭',
                      label: AppStrings.t('khmer'),
                      selected: _selected == AppLang.km,
                      onTap: () => setState(() => _selected = AppLang.km),
                    ),
                    const SizedBox(height: 16),
                    _LanguageTile(
                      flagEmoji: '🇬🇧',
                      label: AppStrings.t('english'),
                      selected: _selected == AppLang.en,
                      onTap: () => setState(() => _selected = AppLang.en),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: AppStrings.t('continue'),
                      onPressed: _continue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flagEmoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flagEmoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyan.withValues(alpha: 0.15)
              : p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.cyan : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: p.textPrimary,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.cyan : p.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
