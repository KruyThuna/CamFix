import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language + theme, held in a [ChangeNotifier] that [CamFixTechApp]
/// listens to so a change rebuilds the whole [MaterialApp] live. Persisted
/// with shared_preferences so choices survive a restart. Mirrors the customer
/// app's `AppSettings`.
enum AppLang { en, km }

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _langKey = 'tech_settings_lang';
  static const _darkKey = 'tech_settings_dark';

  AppLang _lang = AppLang.en;
  ThemeMode _themeMode = ThemeMode.light;

  AppLang get lang => _lang;
  bool get isKm => _lang == AppLang.km;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Load the saved settings. Call once from `main()` before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_langKey) == 'km') _lang = AppLang.km;
    if (prefs.getBool(_darkKey) ?? false) _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setLang(AppLang lang) async {
    if (lang == _lang) return;
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang == AppLang.km ? 'km' : 'en');
  }

  Future<void> toggle() =>
      setLang(_lang == AppLang.en ? AppLang.km : AppLang.en);

  Future<void> setDarkMode(bool on) async {
    final next = on ? ThemeMode.dark : ThemeMode.light;
    if (next == _themeMode) return;
    _themeMode = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, on);
  }
}
