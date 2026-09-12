import 'package:flutter/foundation.dart';

import '../models/technician_profile.dart';
import 'api_client.dart';
import 'technician_api.dart';
import 'token_store.dart';

/// Holds the signed-in technician's profile, refreshed from
/// `GET /api/technician/me`. Screens listen so they render real data and
/// react to approval / availability changes.
class CurrentTechnician extends ChangeNotifier {
  CurrentTechnician._();
  static final CurrentTechnician instance = CurrentTechnician._();

  TechnicianProfile? _value;
  bool _loading = false;
  int _generation = 0;

  TechnicianProfile? get value => _value;
  bool get loading => _loading;

  Future<void> refresh() async {
    final generation = ++_generation;
    if (!await TokenStore.instance.hasToken()) {
      if (generation == _generation) {
        _value = null;
        notifyListeners();
      }
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final profile =
          await TechnicianApi.instance.me(ttl: const Duration(seconds: 30));
      if (generation != _generation) return;
      _value = profile;
    } on ApiException {
      // keep whatever we had; a 401 means the token is stale
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void set(TechnicianProfile profile) {
    _generation++;
    _value = profile;
    notifyListeners();
  }

  void clear() {
    _generation++;
    _value = null;
    notifyListeners();
  }
}
