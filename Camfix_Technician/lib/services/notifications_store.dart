import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/tech_notification.dart';
import 'api_client.dart';
import 'notifications_api.dart';
import 'token_store.dart';

/// Polls the technician's notifications while signed in. Drives the home-screen
/// bell badge and the notifications screen.
class NotificationsStore extends ChangeNotifier {
  NotificationsStore._();
  static final NotificationsStore instance = NotificationsStore._();

  List<TechNotification> _items = const [];
  int _unread = 0;
  bool _loading = false;
  Timer? _poll;
  int _generation = 0;

  List<TechNotification> get items => _items;
  int get unread => _unread;
  bool get loading => _loading;

  Future<void> refresh() async {
    final generation = ++_generation;
    final hasToken = await TokenStore.instance.hasToken();
    if (generation != _generation) return;
    if (!hasToken) {
      _items = const [];
      _unread = 0;
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final list = await NotificationsApi.instance.list();
      if (generation != _generation) return;
      _items = list;
      _unread = list.where((n) => !n.read).length;
    } on ApiException {
      // keep what we had
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void startPolling([Duration interval = const Duration(seconds: 25)]) {
    _poll?.cancel();
    unawaited(refresh());
    _poll = Timer.periodic(interval, (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> markAllRead() async {
    final generation = _generation;
    await NotificationsApi.instance.markAllRead();
    if (generation != _generation) return;
    _generation++;
    _loading = false;
    _items = [for (final n in _items) n.read ? n : n.markRead()];
    _unread = 0;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    final generation = _generation;
    await NotificationsApi.instance.markRead(id);
    if (generation != _generation) return;
    _generation++;
    _loading = false;
    _items = [for (final n in _items) n.id == id ? n.markRead() : n];
    _unread = _items.where((n) => !n.read).length;
    notifyListeners();
  }

  void clear() {
    _generation++;
    stopPolling();
    _items = const [];
    _unread = 0;
    _loading = false;
    notifyListeners();
  }
}
