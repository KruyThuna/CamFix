import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../models/tech_job.dart';
import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../services/location_reporter.dart';
import '../services/notifications_store.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with LangAware<HomeScreen> {
  List<TechJob>? _jobs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CurrentTechnician.instance.addListener(_onProfile);
    CurrentTechnician.instance.refresh();
    _load();
    NotificationsStore.instance.addListener(_onProfile);
    NotificationsStore.instance.startPolling();
    if (CurrentTechnician.instance.value?.available == true) {
      LocationReporter.instance.start();
    }
  }

  @override
  void dispose() {
    CurrentTechnician.instance.removeListener(_onProfile);
    NotificationsStore.instance.removeListener(_onProfile);
    super.dispose();
  }

  void _onProfile() => mounted ? setState(() {}) : null;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = await TechnicianApi.instance.myJobs();
      LocationReporter.instance.onActiveJob = jobs.any((j) => j.isActive);
      if (mounted) setState(() => _jobs = jobs);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final profile = CurrentTechnician.instance.value;
    final jobs = _jobs ?? const <TechJob>[];
    final active = jobs.where((j) => j.isActive).toList();
    final history = jobs.where((j) => !j.isActive).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile?.displayName ?? AppStrings.t('camfixTechnician')),
          actions: [
            IconButton(
              tooltip: AppStrings.t('refresh'),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            _NotificationsBell(
              unread: NotificationsStore.instance.unread,
              onTap: () async {
                await Navigator.pushNamed(context, '/notifications');
                NotificationsStore.instance.refresh();
              },
            ),
            IconButton(
              tooltip: AppStrings.t('tooltipProfile'),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              tooltip: AppStrings.t('signOut'),
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(tabs: [
            Tab(text: AppStrings.t('tabActive')),
            Tab(text: AppStrings.t('tabHistory')),
          ]),
        ),
        body: Column(
          children: [
            if ((profile?.isOperational ?? false) && profile?.bannerUrl == null)
              _GetStartedBannerPrompt(
                onTap: () async {
                  final posted =
                      await Navigator.pushNamed(context, '/get-started-banner');
                  if (posted == true) CurrentTechnician.instance.refresh();
                },
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _JobList(
                            jobs: active,
                            empty: AppStrings.t('noActiveJobs'),
                            emptySubtitle: AppStrings.t('noActiveJobsSubtitle'),
                            onRefresh: _load,
                            onTap: _openJob),
                        _JobList(
                            jobs: history,
                            empty: AppStrings.t('noPastJobs'),
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

/// Prompt shown on the home screen until the technician posts a banner -
/// stays visible (not dismissible) so it's easy to find again, since it's
/// also the entry point for editing/removing the banner later.
class _GetStartedBannerPrompt extends StatelessWidget {
  const _GetStartedBannerPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
          border: Border(bottom: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t('getStartedBannerPromptTitle'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(AppStrings.t('getStartedBannerPromptBody'),
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.empty,
    this.emptySubtitle,
    required this.onRefresh,
    required this.onTap,
  });

  final List<TechJob> jobs;
  final String empty;
  final String? emptySubtitle;
  final Future<void> Function() onRefresh;
  final void Function(TechJob) onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: jobs.isEmpty
          ? ListView(children: [
              const SizedBox(height: 100),
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.work_outline,
                      size: 30, color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                  child: Text(empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: p.textPrimary, fontWeight: FontWeight.w600))),
              if (emptySubtitle != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Text(emptySubtitle!,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 12.5, color: p.textSecondary)),
                  ),
                ),
              ],
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
                            _StatusChip(
                                status: j.status, selfDrop: j.isSelfDrop),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(AppStrings.category(j.category),
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
  const _StatusChip({required this.status, this.selfDrop = false});
  final bool selfDrop;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'IN_PROGRESS' ||
      'ASSIGNED' ||
      'ON_THE_WAY' ||
      'ARRIVED' ||
      'QUOTE_PENDING' =>
        (AppColors.primaryBlue.withValues(alpha: 0.12), AppColors.primaryBlue),
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
      child: Text(AppStrings.jobStatus(status, selfDrop: selfDrop),
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// Bell icon with an unread-count badge for the home app bar.
class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell({required this.unread, required this.onTap});
  final int unread;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: AppStrings.t('tooltipNotifications'),
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE23D3D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
