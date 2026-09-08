import 'package:flutter/material.dart';

import '../models/tech_job.dart';
import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../services/location_reporter.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TechJob>? _jobs;
  bool _loading = true;
  bool _togglingAvailability = false;

  @override
  void initState() {
    super.initState();
    CurrentTechnician.instance.addListener(_onProfile);
    CurrentTechnician.instance.refresh();
    _load();
    if (CurrentTechnician.instance.value?.available == true) {
      LocationReporter.instance.start();
    }
  }

  @override
  void dispose() {
    CurrentTechnician.instance.removeListener(_onProfile);
    super.dispose();
  }

  void _onProfile() => mounted ? setState(() {}) : null;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = await TechnicianApi.instance.myJobs();
      if (mounted) setState(() => _jobs = jobs);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setAvailable(bool value) async {
    setState(() => _togglingAvailability = true);
    try {
      final updated = await TechnicianApi.instance.setAvailability(value);
      CurrentTechnician.instance.set(updated);
      if (value) {
        LocationReporter.instance.start();
      } else {
        LocationReporter.instance.stop();
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }

  Future<void> _signOut() async {
    LocationReporter.instance.stop();
    await AuthApi.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final profile = CurrentTechnician.instance.value;
    final available = profile?.available ?? false;
    final jobs = _jobs ?? const <TechJob>[];
    final active = jobs.where((j) => j.isActive).toList();
    final history = jobs.where((j) => !j.isActive).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile?.displayName ?? 'CAM FIX Technician'),
          actions: [
            IconButton(
              tooltip: 'Profile',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Active'), Tab(text: 'History')]),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: available
                  ? AppColors.success.withValues(alpha: 0.12)
                  : p.surfaceAlt,
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Icon(available ? Icons.podcasts : Icons.pause_circle_outline,
                      color: available ? AppColors.success : p.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      available
                          ? 'You\'re online — sharing your location'
                          : 'You\'re offline',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: p.textPrimary),
                    ),
                  ),
                  if (_togglingAvailability)
                    const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Switch(
                      value: available,
                      activeThumbColor: AppColors.success,
                      onChanged: (profile?.isOperational ?? false)
                          ? _setAvailable
                          : null,
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _JobList(
                            jobs: active,
                            empty: 'No active jobs right now.',
                            onRefresh: _load,
                            onTap: _openJob),
                        _JobList(
                            jobs: history,
                            empty: 'No past jobs yet.',
                            onRefresh: _load,
                            onTap: _openJob),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJob(TechJob job) async {
    await Navigator.pushNamed(context, '/job', arguments: job.id);
    _load();
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.empty,
    required this.onRefresh,
    required this.onTap,
  });

  final List<TechJob> jobs;
  final String empty;
  final Future<void> Function() onRefresh;
  final void Function(TechJob) onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: jobs.isEmpty
          ? ListView(children: [
              const SizedBox(height: 120),
              Center(
                  child: Text(empty, style: TextStyle(color: p.textSecondary))),
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final j = jobs[i];
                return InkWell(
                  onTap: () => onTap(j),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: p.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('#${j.id} · ${j.customerName}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary)),
                            ),
                            _StatusChip(status: j.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(j.category,
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 12.5)),
                        const SizedBox(height: 8),
                        Text(j.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.textPrimary)),
                        if ((j.address ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.place_outlined,
                                size: 15, color: p.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(j.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: p.textSecondary, fontSize: 12.5)),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'IN_PROGRESS' || 'ASSIGNED' => (
          AppColors.primaryBlue.withValues(alpha: 0.12),
          AppColors.primaryBlue
        ),
      'COMPLETED' => (
          AppColors.success.withValues(alpha: 0.15),
          const Color(0xFF1F9D55)
        ),
      _ => (context.pal.surfaceAlt, context.pal.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
