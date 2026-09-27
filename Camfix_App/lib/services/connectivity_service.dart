import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Overall reachability, from "no radio at all" to "really online".
enum NetStatus {
  /// First check hasn't finished yet.
  unknown,

  /// No Wi-Fi / mobile / ethernet transport (airplane mode, Wi-Fi off,
  /// no SIM / no data).
  offline,

  /// A transport exists but the internet isn't actually reachable
  /// (router with no WAN, captive Wi-Fi portal, data quota hit, DNS blocked).
  noInternet,

  /// Transport up *and* a real request to the internet succeeded.
  online,
}

/// Which pipe the device is currently using.
enum NetTransport { none, wifi, mobile, ethernet, vpn, other }

/// Watches the OS connectivity signal *and* verifies the internet is truly
/// reachable (connectivity_plus only says a network interface exists, not that
/// packets get out). Screens/the app shell listen to this so they can show a
/// "No internet connection" banner and gate startup.
///
/// Call [start] once from `main()` / the splash; call [refresh] from any
/// "Retry" affordance.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// Tiny endpoint Android itself uses for captive-portal detection: returns
  /// HTTP 204 with no body when the internet is genuinely reachable. A captive
  /// portal redirects it (200 + login page), so only 204 counts as "online".
  static const _probeUrl = 'https://www.gstatic.com/generate_204';

  final Connectivity _conn = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  NetStatus _status = NetStatus.unknown;
  NetTransport _transport = NetTransport.none;
  bool _checking = false;
  bool _started = false;

  NetStatus get status => _status;
  NetTransport get transport => _transport;

  /// A check is in flight (drives the spinner on the banner / splash).
  bool get checking => _checking;

  bool get isOnline => _status == NetStatus.online;

  /// True for both "no transport" and "transport but no internet".
  bool get isOffline =>
      _status == NetStatus.offline || _status == NetStatus.noInternet;

  /// Begin watching the OS connectivity stream and run the first check.
  /// Safe to call more than once (later calls just await the first check).
  Future<void> start() async {
    if (_started) {
      if (_status == NetStatus.unknown) await refresh();
      return;
    }
    _started = true;
    _sub = _conn.onConnectivityChanged.listen(
      _apply,
      onError: (_) => _set(NetStatus.offline, NetTransport.none),
    );
    await refresh();
  }

  /// Force a fresh transport read + internet probe right now.
  Future<void> refresh() async {
    if (_checking) return;
    _checking = true;
    notifyListeners();
    try {
      List<ConnectivityResult> results;
      try {
        results = await _conn
            .checkConnectivity()
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        results = const [ConnectivityResult.none];
      }
      await _apply(results);
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  Future<void> _apply(List<ConnectivityResult> results) async {
    final transport = _mapTransport(results);
    if (transport == NetTransport.none) {
      _set(NetStatus.offline, transport);
      return;
    }
    final reachable = await _hasInternet();
    _set(reachable ? NetStatus.online : NetStatus.noInternet, transport);
  }

  NetTransport _mapTransport(List<ConnectivityResult> r) {
    if (r.contains(ConnectivityResult.wifi)) return NetTransport.wifi;
    if (r.contains(ConnectivityResult.mobile)) return NetTransport.mobile;
    if (r.contains(ConnectivityResult.ethernet)) return NetTransport.ethernet;
    if (r.contains(ConnectivityResult.vpn)) return NetTransport.vpn;
    final onlyNone = r.isEmpty || r.every((e) => e == ConnectivityResult.none);
    return onlyNone ? NetTransport.none : NetTransport.other;
  }

  Future<bool> _hasInternet() async {
    // Browsers block cross-origin probes (CORS) and expose no raw sockets, so
    // on web we trust connectivity_plus, which is backed by `navigator.onLine`.
    if (kIsWeb) return true;
    try {
      final res = await http
          .get(Uri.parse(_probeUrl))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  void _set(NetStatus status, NetTransport transport) {
    if (status == _status && transport == _transport) return;
    _status = status;
    _transport = transport;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
