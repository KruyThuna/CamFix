import 'package:flutter/material.dart';

import '../models/technician_profile.dart';
import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../theme/app_theme.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  @override
  void initState() {
    super.initState();
    CurrentTechnician.instance.addListener(_onChange);
    CurrentTechnician.instance.refresh();
  }

  @override
  void dispose() {
    CurrentTechnician.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final p = CurrentTechnician.instance.value;
    if (mounted && p != null && p.isApproved && !p.isSuspended) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    await AuthApi.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  ({IconData icon, Color color, String title, String body}) _content(
      TechnicianProfile? p) {
    if (p == null) {
      return (
        icon: Icons.hourglass_empty,
        color: AppColors.primaryBlue,
        title: 'Checking your status…',
        body: 'Pull down to refresh.',
      );
    }
    if (p.isRejected) {
      return (
        icon: Icons.cancel_outlined,
        color: const Color(0xFFD13438),
        title: 'Application not approved',
        body: p.rejectionReason?.isNotEmpty == true
            ? p.rejectionReason!
            : 'Contact CAM FIX support for details.',
      );
    }
    if (p.isSuspended) {
      return (
        icon: Icons.pause_circle_outline,
        color: const Color(0xFFD13438),
        title: 'Account suspended',
        body: 'Your technician account is currently suspended. '
            'Contact CAM FIX support.',
      );
    }
    return (
      icon: Icons.hourglass_top_rounded,
      color: AppColors.primaryBlue,
      title: 'Waiting for approval',
      body: 'An admin is reviewing your registration. You\'ll get an email '
          'once you\'re approved — pull down to check again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final profile = CurrentTechnician.instance.value;
    final c = _content(profile);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAM FIX Technician'),
        actions: [
          TextButton(onPressed: _signOut, child: const Text('Sign out')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => CurrentTechnician.instance.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const SizedBox(height: 40),
            Icon(c.icon, size: 72, color: c.color),
            const SizedBox(height: 20),
            Text(c.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            const SizedBox(height: 10),
            Text(c.body,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, height: 1.4)),
            if (profile != null) ...[
              const SizedBox(height: 28),
              Center(
                child: Text(
                    '${profile.displayName} · ${profile.category}',
                    style: TextStyle(color: p.textSecondary, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
