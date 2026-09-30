import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'current_technician.dart';
import 'device_location.dart';
import 'technician_api.dart';

/// Streams the technician's GPS position to the backend in near real time
/// while they are available (or driving to an active job) and the app is
/// foregrounded, so the customer's map follows them live.
///
/// Positions come from the platform location stream (a new fix every
/// [_distanceFilterM] metres moved) and are sent at most every [_minGap];
/// [_heartbeat] re-sends the last fix while standing still so the customer
/// sees a fresh "last updated" time. Best-effort: any read/permission/network
/// failure is swallowed and retried on the next fix.
class LocationReporter with WidgetsBindingObserver {
  LocationReporter._();
  static final LocationReporter instance = LocationReporter._();

  static const _distanceFilterM = 10;
  static const _minGap = Duration(seconds: 3);
  static const _heartbeat = Duration(seconds: 20);

  StreamSubscription<Position>? _sub;
  Timer? _heartbeatTimer;
  bool _foreground = true;
  bool _sending = false;
  bool _onActiveJob = false;
  Position? _last;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isRunning => _heartbeatTimer != null;

  /// Keep reporting while the technician has a job in progress, even if they
  /// switched "available" off - the customer is still waiting on them.
  bool get onActiveJob => _onActiveJob;
  set onActiveJob(bool value) {
    _onActiveJob = value;
    if (value) start();
  }

  void start() {
    if (_heartbeatTimer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) => _heartbeatTick());
    _listen();
  }

  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _sub?.cancel();
    _sub = null;
    _last = null;
    _onActiveJob = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // The OS may kill the stream while backgrounded - reopen on return.
    if (_foreground && isRunning && _sub == null) _listen();
  }

  bool get _shouldReport {
    if (!_foreground) return false;
    final profile = CurrentTechnician.instance.value;
    if (profile == null || !profile.isOperational) return false;
    return profile.available || _onActiveJob;
  }

  /// One-shot read first (surfaces permission prompts, sends immediately),
  /// then subscribe to the continuous stream.
  Future<void> _listen() async {
    final first = await getCurrentLocation();
    if (!isRunning) return;
    if (first.position != null) _onFix(first.position!);
    if (!first.ok) return; // no permission / GPS off - heartbeat retries
    _sub ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _distanceFilterM,
      ),
    ).listen(_onFix, onError: (_) {
      _sub?.cancel();
      _sub = null; // heartbeat will try to reopen
    });
  }

  void _onFix(Position pos) {
    _last = pos;
    if (DateTime.now().difference(_lastSentAt) >= _minGap) _send(pos);
  }

  void _heartbeatTick() {
    if (_sub == null) {
      _listen();
      return;
    }
    if (_last != null) _send(_last!);
  }

  Future<void> _send(Position pos) async {
    if (_sending || !_shouldReport) return;
    _sending = true;
    _lastSentAt = DateTime.now();
    try {
      await TechnicianApi.instance.pushLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // swallow; the next fix / heartbeat retries
    } finally {
      _sending = false;
    }
  }
}
