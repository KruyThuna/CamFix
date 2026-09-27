import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The customer's own recent search queries on the Search screen - real
/// history they typed, persisted locally. Never sent anywhere; purely a
/// convenience list, most-recent first.
class SearchHistoryStore extends ChangeNotifier {
  SearchHistoryStore._();
  static final SearchHistoryStore instance = SearchHistoryStore._();

  static const _kKey = 'search_history';
  static const _kMax = 8;

  List<String> _items = const [];
  List<String> get items => _items;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _items = prefs.getStringList(_kKey) ?? const [];
    } catch (_) {
      _items = const [];
    }
    notifyListeners();
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final next = [
      trimmed,
      ..._items.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ];
    _items = next.take(_kMax).toList();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kKey, _items);
    } catch (_) {/* keep it in memory even if the write fails */}
  }

  Future<void> clear() async {
    _items = const [];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kKey);
    } catch (_) {/* keep it cleared in memory even if the write fails */}
  }
}
