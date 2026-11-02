import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/language.dart';
import '../../services/connectivity_service.dart';
import '../../services/current_user.dart';
import '../../services/token_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_camfix_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _net = ConnectivityService.instance;
  bool _blocked = false;

  late final AnimationController _textController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _textController,
    curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _net.addListener(_onNet);
    _textController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_boot());
    });
  }

  Future<void> _boot() async {
    // Check Wi-Fi / mobile / no-connection *and* real internet reachability
    // before leaving the splash.
    await _net.start();
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted || !_isCurrent) return; // deep-linked past the splash
    if (_net.isOffline) {
      setState(() => _blocked = true); // wait for internet or the user
    } else {
      _go();
    }
  }

  void _onNet() {
    if (!mounted || !_blocked) return;
    if (_net.isOnline) {
      _go();
    } else {
      setState(() {}); // reflect "checking" / status on the retry UI
    }
  }

  Future<void> _retry() async {
    await _net.refresh();
    if (!mounted) return;
    if (_net.isOnline) _go();
  }

  bool get _isCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  Future<void> _go() async {
    _net.removeListener(_onNet);
    if (!mounted || !_isCurrent) return;
    final signedIn = await TokenStore.instance.hasToken();
    if (!mounted || !_isCurrent) return;
    if (signedIn) {
      unawaited(CurrentUser.instance.refresh());
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/language');
    }
  }

  @override
  void dispose() {
    _net.removeListener(_onNet);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimatedCamFixLogo.backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedCamFixLogo(),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    const Text(
                      'CAM FIX',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'On-Demand Home Services',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            if (!_blocked) const _AnimatedPulseDots(),
            if (_blocked) ...[
              const SizedBox(height: 12),
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.primaryBlue, size: 26),
              const SizedBox(height: 10),
              Text(
                AppStrings.t('netOffline'),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t('netCheckConnection'),
                style: const TextStyle(
                  color: AppColors.hintGrey,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _net.checking ? null : _retry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _net.checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue),
                        ),
                      )
                    : Text(AppStrings.t('retry')),
              ),
              TextButton(
                onPressed: _go,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue),
                child: Text(AppStrings.t('continueAnyway')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A sleek 3-dot pulsing loading wave indicator.
class _AnimatedPulseDots extends StatefulWidget {
  const _AnimatedPulseDots();

  @override
  State<_AnimatedPulseDots> createState() => _AnimatedPulseDotsState();
}

class _AnimatedPulseDotsState extends State<_AnimatedPulseDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_anim.value - i * 0.22) % 1.0;
            final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1.0 - t) * 2);
            final opacity = 0.4 + 0.6 * (t < 0.5 ? t * 2 : (1.0 - t) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
