import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'current_technician.dart';
import 'technician_api.dart';

/// The signed-in technician's profile photo.
///
/// Held as raw bytes and persisted (base64) in shared_preferences, so it shows
/// instantly on every screen and survives an app restart, while also being
/// uploaded to `POST /api/technician/me/photo` so it follows the account to
/// any other browser/device (served back from `GET /api/technician/{id}/photo`
/// via [CurrentTechnician]'s `photoUrl`). The picker downscales to 512px /
/// quality 70 so both the local cache and the upload stay small.
class ProfileImage extends ChangeNotifier {
  ProfileImage._();
  static final ProfileImage instance = ProfileImage._();

  static const _key = 'tech_profile_image_b64';
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
    try {
      final updated = await TechnicianApi.instance.uploadPhoto(
        data,
        filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
        contentType: file.mimeType ?? 'image/jpeg',
      );
      CurrentTechnician.instance.set(updated);
    } catch (_) {/* offline or server hiccup - the local copy still shows */}
    return true;
  }

  Future<void> clear() async {
    _bytes = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
    try {
      final updated = await TechnicianApi.instance.deletePhoto();
      CurrentTechnician.instance.set(updated);
    } catch (_) {/* offline or server hiccup - it's gone locally either way */}
  }
}
