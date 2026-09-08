import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/connectivity_service.dart';
import '../services/current_user.dart';
import '../services/token_store.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _net = ConnectivityService.instance;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _net.addListener(_onNet);
    _boot();
  }

  Future<void> _boot() async {
    // Check Wi-Fi / mobile / no-connection *and* real internet reachability
    // before leaving the splash.
    await _net.start();
    await Future<void>.delayed(const Duration(seconds: 2));
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

  /// The splash may sit *under* a deep-linked route in the initial stack
  /// (e.g. opening the app straight on `/live-tracking`). Never navigate then.
  bool get _isCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  Future<void> _go() async {
    _net.removeListener(_onNet);
    if (!mounted || !_isCurrent) return;
    // A JWT from a previous session means the user is still signed in — go
    // straight to the app instead of the language / login flow.
    final signedIn = await TokenStore.instance.hasToken();
    if (!mounted || !_isCurrent) return;
    if (signedIn) {
      unawaited(CurrentUser.instance.refresh()); // warm the profile
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/language');
    }
  }

  @override
  void dispose() {
    _net.removeListener(_onNet);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primaryBlue,
                size: 44,
              ),
            ),
            if (_blocked) ...[
              const SizedBox(height: 28),
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.white, size: 26),
              const SizedBox(height: 10),
              Text(
                AppStrings.t('netOffline'),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t('netCheckConnection'),
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _net.checking ? null : _retry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(AppStrings.t('retry')),
              ),
              TextButton(
                onPressed: _go,
                style: TextButton.styleFrom(foregroundColor: AppColors.white),
                child: Text(AppStrings.t('continueAnyway')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
