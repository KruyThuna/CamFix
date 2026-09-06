import 'package:flutter/foundation.dart';

import '../models/user_info.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Holds the signed-in user's profile, refreshed from `GET /api/auth/me`.
/// Screens listen to this so they show real data, not placeholders.
class CurrentUser extends ChangeNotifier {
  CurrentUser._();
  static final CurrentUser instance = CurrentUser._();

  UserInfo? _value;
  bool _loading = false;

  UserInfo? get value => _value;
  bool get loading => _loading;

  /// Pull the latest profile. No-op (clears) if there's no token.
  Future<void> refresh() async {
    if (!await TokenStore.instance.hasToken()) {
      _value = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final json = await ApiClient.instance.getJson('/api/auth/me');
      _value = UserInfo.fromJson(json);
    } on ApiException {
      // keep whatever we had; a 401 means the token is stale
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void set(UserInfo user) {
    _value = user;
    notifyListeners();
  }

  void clear() {
    _value = null;
    notifyListeners();
  }
}
