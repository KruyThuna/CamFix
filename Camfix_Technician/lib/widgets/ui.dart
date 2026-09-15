import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Compact "switch to the other language" pill. Shows the name of the language
/// it will switch TO, so it reads as an action.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.onSurface = false});

  /// When true, use colours that read on a coloured (gradient) surface.
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = onSurface ? Colors.white : AppColors.primaryBlue;
    // Listen so the label follows the language even when this widget is
    // built `const` by its parent.
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => TextButton.icon(
        onPressed: () => AppSettings.instance.toggle(),
        icon: Icon(Icons.language, size: 18, color: fg),
        label: Text(AppStrings.t('languageName'),
            style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          backgroundColor:
              onSurface ? Colors.white.withValues(alpha: 0.15) : p.surfaceAlt,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }
}

/// Full-width filled button with a busy state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Labelled text field matching the app's rounded style.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
    this.hint,
    this.maxLines = 1,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? hint;
  final int maxLines;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary)),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: p.surfaceAlt,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

void showError(BuildContext context, Object error) {
  final msg = error.toString().replaceFirst(RegExp(r'^ApiException\(\d+\): '), '');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.deepBlue));
}
