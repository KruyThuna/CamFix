import '../models/tech_notification.dart';
import 'api_client.dart';

/// The signed-in technician's notification feed (`/api/notifications/mine`).
class NotificationsApi {
  NotificationsApi._();
  static final NotificationsApi instance = NotificationsApi._();

  final _client = ApiClient.instance;

  Future<List<TechNotification>> list() async {
    final res = await _client.getJsonList('/api/notifications/mine');
    return res.map(TechNotification.fromJson).toList();
  }

  Future<int> unreadCount() async {
    final j = await _client.getJson('/api/notifications/mine/unread-count');
    return (j['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAllRead() => _client
      .postJson('/api/notifications/mine/read-all', const {}, withAuth: true);

  Future<void> markRead(int id) => _client
      .postJson('/api/notifications/mine/$id/read', const {}, withAuth: true);
}
