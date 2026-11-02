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

class _SplashScreenState extends State<SplashScreen> {
  final _net = ConnectivityService.instance;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _net.addListener(_onNet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_boot());
    });
  }

  Future<void> _boot() async {
    // Check Wi-Fi / mobile / no-connection *and* real internet reachability
    // before leaving the splash.
    await _net.start();
    await Future<void>.delayed(const Duration(milliseconds: 2000));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AnimatedCamFixLogo.backgroundColor,
      body: Stack(
        children: [
          // Center: The pure standalone Mascot Logo from Figma "Page 1 - Splash"
          const Center(
            child: AnimatedCamFixLogo(),
          ),
          // Network retry overlay only if completely offline
          if (_blocked)
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.primaryBlue, size: 26),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
