import 'package:flutter/material.dart';

import '../services/current_technician.dart';
import '../services/token_store.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!await TokenStore.instance.hasToken()) {
      _go('/login');
      return;
    }
    await CurrentTechnician.instance.refresh();
    final profile = CurrentTechnician.instance.value;
    if (!mounted) return;
    if (profile == null) {
      _go('/login'); // token stale / rejected
    } else if (profile.isApproved && !profile.isSuspended) {
      _go('/home');
    } else {
      _go('/pending');
    }
  }

  void _go(String route) {
    if (mounted) Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blueGradient),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.handyman_rounded, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text('CAM FIX',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            Text('Technician',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
            SizedBox(height: 28),
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
