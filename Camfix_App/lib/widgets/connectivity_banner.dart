import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// Wraps the whole app (via `MaterialApp.builder`) and drops a strip along the
/// bottom of every screen whenever the device loses internet — and a brief
/// green "Back online" strip when it returns. Sits above all routes and
/// dialogs so the state is visible "at all scales".
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final _svc = ConnectivityService.instance;
  NetStatus _prev = ConnectivityService.instance.status;
  bool _showBackOnline = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
  }

  void _onChange() {
    final now = _svc.status;
    if (now != _prev) {
      final recovered = (_prev == NetStatus.offline ||
              _prev == NetStatus.noInternet) &&
          now == NetStatus.online;
      _prev = now;
      if (recovered) {
        _showBackOnline = true;
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showBackOnline = false);
        });
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _svc.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? bar;
    final s = _svc.status;
    if (s == NetStatus.offline || s == NetStatus.noInternet) {
      bar = _Bar(
        color: const Color(0xFFD64545),
        icon: Icons.wifi_off_rounded,
        title: AppStrings.t(
            s == NetStatus.offline ? 'netOffline' : 'netNoInternet'),
        subtitle: AppStrings.t('netCheckConnection'),
        busy: _svc.checking,
        onRetry: _svc.refresh,
      );
    } else if (_showBackOnline) {
      bar = _Bar(
        color: const Color(0xFF2ECC71),
        icon: Icons.wifi_rounded,
        title: AppStrings.t('netBackOnline'),
      );
    }

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: widget.child),
        if (bar != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(top: false, child: bar),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.busy = false,
    this.onRetry,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool busy;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: busy ? null : () => onRetry!(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(44, 36),
                ),
                child: busy
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
          ],
        ),
      ),
    );
  }
}
