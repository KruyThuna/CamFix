import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user's profile photo.
///
/// Held as raw bytes and persisted (base64) in shared_preferences, so it shows
/// on every screen and survives an app restart. The picker downscales to
/// 512px / quality 70 so the stored string stays small. Purely local for now —
/// wire an upload endpoint later if the backend gets one.
class ProfileImage extends ChangeNotifier {
  ProfileImage._();
  static final ProfileImage instance = ProfileImage._();

  static const _key = 'profile_image_b64';
  final ImagePicker _picker = ImagePicker();

  Uint8List? _bytes;
  Uint8List? get bytes => _bytes;
  bool get hasImage => _bytes != null && _bytes!.isNotEmpty;

  /// Restore the saved photo. Call once from `main()` before `runApp`.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString(_key);
      if (b64 != null && b64.isNotEmpty) _bytes = base64Decode(b64);
    } catch (_) {
      _bytes = null;
    }
    notifyListeners();
  }

  /// Pick a photo from [source], set it as the profile picture and persist it.
  /// Returns false if the user cancelled.
  Future<bool> pickAndSet(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (file == null) return false;
    final data = await file.readAsBytes();
    _bytes = data;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, base64Encode(data));
    } catch (_) {/* keep it in memory even if the write fails */}
    return true;
  }

  Future<void> clear() async {
    _bytes = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
