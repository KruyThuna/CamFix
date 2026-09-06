import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// White, rounded, pill-shaped text field with a leading icon, matching the
/// input fields seen on Login / Sign Up / Password screens.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.suffix,
  });

  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppText.bodyDark.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.hintGrey, fontSize: 15),
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: AppColors.hintGrey, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}
