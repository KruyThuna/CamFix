import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_camfix_logo.dart';

/// Every successful sign-in (email, phone OTP, Google, email verification,
/// new password) ends here: the animated CAMFIX logo, a "Welcome" line,
/// then the dashboard - so all login paths share the same animation.
void goToDashboardAfterLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const LoginSuccessScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
    (route) => false,
  );
}

class LoginSuccessScreen extends StatefulWidget {
  const LoginSuccessScreen({super.key});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    CurrentUser.instance.refresh(); // warm the profile for the dashboard
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _text.forward();
    });
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = CurrentUser.instance.value?.displayName.trim() ?? '';
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final fade = CurvedAnimation(parent: _text, curve: Curves.easeOut);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AnimatedCamFixLogo.backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedCamFixLogo(),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(fade),
                  child: Column(children: [
                    Text(
                      first.isEmpty
                          ? AppStrings.t('welcomeBack')
                          : '${AppStrings.t('welcomeBack')}, $first',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(AppStrings.t('signedInLoading'),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.hintGrey)),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: AppColors.primaryBlue),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
