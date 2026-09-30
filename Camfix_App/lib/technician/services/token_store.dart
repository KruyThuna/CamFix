import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT returned by the auth endpoints so the technician stays
/// signed in across app launches.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _key = 'tech_auth_token';
  String? _cached;

  Future<void> save(String token) async {
    _cached = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<String?> read() async {
    if (_cached != null) return _cached;
    final prefs = await SharedPreferences.getInstance();
    return _cached = prefs.getString(_key);
  }

  Future<bool> hasToken() async => (await read())?.isNotEmpty ?? false;

  Future<void> clear() async {
    _cached = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
