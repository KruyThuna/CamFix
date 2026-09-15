import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide UI preferences (theme brightness + language), held in a single
/// [ChangeNotifier] listened to by [CamFixApp] so changes rebuild the whole
/// [MaterialApp] live. Persisted with shared_preferences so the choice
/// survives an app restart.
enum AppLang { en, km }

/// Unit used to display straight-line / route distances (nearby technicians,
/// booking tracking ETA, ...).
enum DistanceUnit { km, mi }

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _langKey = 'settings_lang';
  static const _darkKey = 'settings_dark';
  static const _unitKey = 'settings_distance_unit';
  static const _notifKey = 'settings_notifications_enabled';
  static const _addrKey = 'settings_default_address';
  static const _addrLatKey = 'settings_default_address_lat';
  static const _addrLngKey = 'settings_default_address_lng';

  ThemeMode _themeMode = ThemeMode.light;
  AppLang _lang = AppLang.en;
  DistanceUnit _distanceUnit = DistanceUnit.km;
  bool _notificationsEnabled = true;
  String? _defaultAddress;
  double? _defaultLat;
  double? _defaultLng;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  AppLang get lang => _lang;
  DistanceUnit get distanceUnit => _distanceUnit;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get defaultAddress => _defaultAddress;
  double? get defaultAddressLat => _defaultLat;
  double? get defaultAddressLng => _defaultLng;
  bool get hasDefaultAddress =>
      _defaultAddress != null && _defaultLat != null && _defaultLng != null;

  /// Load the saved preferences. Call once from `main()` before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_langKey);
    if (lang == 'km') _lang = AppLang.km;
    if (prefs.getBool(_darkKey) ?? false) _themeMode = ThemeMode.dark;
    if (prefs.getString(_unitKey) == 'mi') _distanceUnit = DistanceUnit.mi;
    _notificationsEnabled = prefs.getBool(_notifKey) ?? true;
    _defaultAddress = prefs.getString(_addrKey);
    _defaultLat = prefs.getDouble(_addrLatKey);
    _defaultLng = prefs.getDouble(_addrLngKey);
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

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    if (unit == _distanceUnit) return;
    _distanceUnit = unit;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit == DistanceUnit.mi ? 'mi' : 'km');
  }

  Future<void> setNotificationsEnabled(bool on) async {
    if (on == _notificationsEnabled) return;
    _notificationsEnabled = on;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, on);
  }

  Future<void> setDefaultAddress(String address, double lat, double lng) async {
    _defaultAddress = address;
    _defaultLat = lat;
    _defaultLng = lng;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addrKey, address);
    await prefs.setDouble(_addrLatKey, lat);
    await prefs.setDouble(_addrLngKey, lng);
  }

  Future<void> clearDefaultAddress() async {
    _defaultAddress = null;
    _defaultLat = null;
    _defaultLng = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_addrKey);
    await prefs.remove(_addrLatKey);
    await prefs.remove(_addrLngKey);
  }

  /// Convert a straight-line/route distance in kilometres to the user's
  /// chosen [distanceUnit]. Pure unit math — no localisation here (that's
  /// `AppStrings.t(distanceUnitKey)`) to avoid an app_settings ↔ app_strings
  /// import cycle.
  double convertKm(double km) =>
      _distanceUnit == DistanceUnit.mi ? km * 0.621371 : km;

  /// The `AppStrings` key for the current unit's short label
  /// ('kmShort' / 'miShort').
  String get distanceUnitKey =>
      _distanceUnit == DistanceUnit.mi ? 'miShort' : 'kmShort';
}
