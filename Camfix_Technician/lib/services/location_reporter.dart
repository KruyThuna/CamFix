import 'dart:async';

import 'package:flutter/widgets.dart';

import 'current_technician.dart';
import 'device_location.dart';
import 'technician_api.dart';

/// Periodically pushes the technician's GPS position to the backend while
/// they are marked available and the app is foregrounded. Best-effort: any
/// read/permission/network failure is swallowed and retried next tick.
class LocationReporter with WidgetsBindingObserver {
  LocationReporter._();
  static final LocationReporter instance = LocationReporter._();

  static const _interval = Duration(seconds: 45);

  Timer? _timer;
  bool _foreground = true;
  bool _sending = false;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_interval, (_) => _tick());
    _tick(); // send one immediately
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  Future<void> _tick() async {
    if (_sending || !_foreground) return;
    final profile = CurrentTechnician.instance.value;
    if (profile == null || !profile.available || !profile.isOperational) return;
    _sending = true;
    try {
      final loc = await getCurrentLocation();
      final pos = loc.position;
      if (pos != null) {
        await TechnicianApi.instance.pushLocation(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // swallow; try again next tick
    } finally {
      _sending = false;
    }
  }
}
