import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide UI preferences (theme brightness + language), held in a single
/// [ChangeNotifier] listened to by [CamFixApp] so changes rebuild the whole
/// [MaterialApp] live. Persisted with shared_preferences so the choice
/// survives an app restart.
enum AppLang { en, km }

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _langKey = 'settings_lang';
  static const _darkKey = 'settings_dark';

  ThemeMode _themeMode = ThemeMode.light;
  AppLang _lang = AppLang.en;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  AppLang get lang => _lang;

  /// Load the saved preferences. Call once from `main()` before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_langKey);
    if (lang == 'km') _lang = AppLang.km;
    if (prefs.getBool(_darkKey) ?? false) _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setDarkMode(bool on) async {
    final next = on ? ThemeMode.dark : ThemeMode.light;
    if (next == _themeMode) return;
    _themeMode = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, on);
  }

  Future<void> setLang(AppLang lang) async {
    if (lang == _lang) return;
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang == AppLang.km ? 'km' : 'en');
  }
}
