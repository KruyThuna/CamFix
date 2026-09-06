import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT returned by the auth endpoints so the user stays signed in
/// across app launches.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _key = 'auth_token';
  static const _emailsKey = 'known_emails';
  String? _cached;

  /// Emails the user has signed in with before (most-recent first), so the
  /// "Continue with Google" fallback can offer a pick-list instead of a field.
  Future<List<String>> knownEmails() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_emailsKey) ?? const [];
  }

  Future<void> rememberEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_emailsKey) ?? <String>[];
    list.remove(e);
    list.insert(0, e);
    await prefs.setStringList(_emailsKey, list.take(5).toList());
  }

  /// Drop [email] from the remembered list ("Remove an account").
  Future<void> forgetEmail(String email) async {
    final e = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_emailsKey) ?? <String>[];
    if (list.remove(e)) {
      await prefs.setStringList(_emailsKey, list);
    }
  }

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
