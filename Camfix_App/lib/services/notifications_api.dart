import '../models/app_notification.dart';
import 'api_client.dart';

/// Calls against the signed-in user's notification feed (`/api/notifications/mine`).
class NotificationsApi {
  NotificationsApi._();
  static final NotificationsApi instance = NotificationsApi._();

  final _c = ApiClient.instance;

  Future<List<AppNotification>> list() async {
    final raw = await _c.getJsonList('/api/notifications/mine');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<int> unreadCount() async {
    final j = await _c.getJson('/api/notifications/mine/unread-count');
    return (j['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead() =>
      _c.postJson('/api/notifications/mine/read-all', const {}, withAuth: true);

  Future<void> markRead(int id) =>
      _c.postJson('/api/notifications/mine/$id/read', const {}, withAuth: true);
}
