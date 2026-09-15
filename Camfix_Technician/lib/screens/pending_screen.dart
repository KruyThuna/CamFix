import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/technician_profile.dart';
import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen>
    with LangAware<PendingScreen> {
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
        title: AppStrings.t('checkingStatus'),
        body: AppStrings.t('pullToRefresh'),
      );
    }
    if (p.isRejected) {
      return (
        icon: Icons.cancel_outlined,
        color: const Color(0xFFD13438),
        title: AppStrings.t('notApprovedTitle'),
        body: p.rejectionReason?.isNotEmpty == true
            ? p.rejectionReason!
            : AppStrings.t('contactSupportDetails'),
      );
    }
    if (p.isSuspended) {
      return (
        icon: Icons.pause_circle_outline,
        color: const Color(0xFFD13438),
        title: AppStrings.t('accountSuspendedTitle'),
        body: AppStrings.t('accountSuspendedBody'),
      );
    }
    return (
      icon: Icons.hourglass_top_rounded,
      color: AppColors.primaryBlue,
      title: AppStrings.t('waitingApprovalTitle'),
      body: AppStrings.t('waitingApprovalBody'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final profile = CurrentTechnician.instance.value;
    final c = _content(profile);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('camfixTechnician')),
        actions: [
          const Center(child: LanguageToggle()),
          const SizedBox(width: 4),
          TextButton(
              onPressed: _signOut, child: Text(AppStrings.t('signOut'))),
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
                    '${profile.displayName} · ${AppStrings.category(profile.category)}',
                    style: TextStyle(color: p.textSecondary, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
