import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app_settings.dart';
import '../models/app_notification.dart';
import 'api_client.dart';
import 'notifications_api.dart';
import 'token_store.dart';

/// Holds the user's notifications + unread count, polled from the backend while
/// signed in. Listened to by the dashboard bell (badge) and the notifications
/// screen.
class NotificationsStore extends ChangeNotifier {
  NotificationsStore._();
  static final NotificationsStore instance = NotificationsStore._();

  List<AppNotification> _items = const [];
  int _unread = 0;
  bool _loading = false;
  Timer? _poll;

  List<AppNotification> get items => _items;
  int get unread => _unread;
  bool get loading => _loading;

  Future<void> refresh() async {
    if (!await TokenStore.instance.hasToken()) {
      _items = const [];
      _unread = 0;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final list = await NotificationsApi.instance.list();
      _items = list;
      _unread = list.where((n) => !n.read).length;
    } on ApiException {
      // keep whatever we had; a transient error shouldn't blank the list
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh now, then every [interval]. Safe to call repeatedly. A no-op
  /// while the user has turned notifications off in Profile settings.
  void startPolling([Duration interval = const Duration(seconds: 25)]) {
    _poll?.cancel();
    if (!AppSettings.instance.notificationsEnabled) return;
    unawaited(refresh());
    _poll = Timer.periodic(interval, (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> markAllRead() async {
    await NotificationsApi.instance.markAllRead();
    _items = [for (final n in _items) n.read ? n : n.markRead()];
    _unread = 0;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    await NotificationsApi.instance.markRead(id);
    _items = [for (final n in _items) n.id == id ? n.markRead() : n];
    _unread = _items.where((n) => !n.read).length;
    notifyListeners();
  }

  void clear() {
    stopPolling();
    _items = const [];
    _unread = 0;
    notifyListeners();
  }
}
