import 'package:geolocator/geolocator.dart';

/// Outcome of a one-shot GPS read: either a [position], or an [errorKey]
/// (an i18n key the caller can show in a snackbar).
class LocationResult {
  const LocationResult({this.position, this.errorKey});
  final Position? position;
  final String? errorKey;
  bool get ok => position != null;
}

/// Check location services + permission, then read the current position.
/// Never throws — failures come back as [LocationResult.errorKey].
Future<LocationResult> getCurrentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(errorKey: 'locationServiceOff');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return const LocationResult(errorKey: 'locationPermissionDenied');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return LocationResult(position: pos);
  } catch (_) {
    return const LocationResult(errorKey: 'locationFailed');
  }
}

/// Great-circle distance in kilometres between two points. Backend
/// `/api/technicians` doesn't compute distance itself (it's a flat list, no
/// lat/lng query support), so "nearby" is worked out here on-device from the
/// user's real GPS fix and each technician's real reported position.
double distanceKmBetween(double lat1, double lng1, double lat2, double lng2) {
  return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
}
