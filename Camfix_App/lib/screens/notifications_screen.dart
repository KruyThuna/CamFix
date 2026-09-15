import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/app_notification.dart';
import '../services/notifications_store.dart';
import '../theme/app_theme.dart';

/// The user's in-app notification feed. Reads [NotificationsStore]; tapping a
/// row marks it read. All copy follows the app language (notification text
/// itself is sent bilingual by the backend).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationsStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
    _store.refresh();
    AppSettings.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    AppSettings.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  String _relative(DateTime? t) {
    if (t == null) return '';
    final mins = DateTime.now().difference(t).inMinutes;
    if (mins < 1) return AppStrings.t('justNow');
    if (mins < 60) return '$mins ${AppStrings.t('minAgo')}';
    final hrs = mins ~/ 60;
    if (hrs < 24) return '$hrs ${AppStrings.t('hrAgo')}';
    return '${hrs ~/ 24} ${AppStrings.t('dayAgo')}';
  }

  IconData _icon(String type) => switch (type) {
        'BOOKING_REQUESTED' => Icons.event_available_rounded,
        'JOB_ASSIGNED' => Icons.engineering_rounded,
        'JOB_IN_PROGRESS' => Icons.handyman_rounded,
        'JOB_COMPLETED' => Icons.check_circle_rounded,
        'JOB_CANCELLED' => Icons.cancel_rounded,
        'JOB_DECLINED' => Icons.autorenew_rounded,
        _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = _store.items;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(AppStrings.t('notifications')),
        actions: [
          if (_store.unread > 0)
            TextButton(
              onPressed: () => _store.markAllRead(),
              child: Text(AppStrings.t('markAllRead'),
                  style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _store.refresh,
        child: items.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                  Icon(Icons.notifications_off_outlined,
                      size: 48, color: p.textSecondary),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(AppStrings.t('notificationsEmpty'),
                        style: TextStyle(color: p.textSecondary)),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: p.border),
                itemBuilder: (context, i) => _row(context, items[i]),
              ),
      ),
    );
  }

  Widget _row(BuildContext context, AppNotification n) {
    final p = context.pal;
    return InkWell(
      onTap: () {
        if (!n.read) _store.markRead(n.id);
        if (n.jobId != null) {
          Navigator.of(context)
              .pushNamed('/booking-tracking', arguments: n.jobId);
        }
      },
      child: Container(
        color: n.read ? null : AppColors.primaryBlue.withValues(alpha: 0.06),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
              child: Icon(_icon(n.type),
                  size: 18, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.localizedTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                n.read ? FontWeight.w600 : FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.localizedMessage,
                      style: TextStyle(fontSize: 13, color: p.textSecondary)),
                  const SizedBox(height: 5),
                  Text(_relative(n.createdAt),
                      style: TextStyle(fontSize: 11, color: p.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
