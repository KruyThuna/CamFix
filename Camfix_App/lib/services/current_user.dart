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
    } on ApiException catch (e) {
      // A 401 means the saved JWT is expired / revoked — drop it so the next
      // launch shows the login flow instead of a broken signed-in state.
      // Any other error (server down, no network) leaves the token in place.
      if (e.statusCode == 401) {
        await TokenStore.instance.clear();
        _value = null;
      }
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
