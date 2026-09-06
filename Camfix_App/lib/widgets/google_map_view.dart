import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

import '../models/route_traffic.dart';
import '../services/directions_api.dart';

/// The live-tracking map rendered with **real Google Maps** — Google's own
/// tiles and live traffic layer (`trafficEnabled`), the route(s) from the
/// Directions API when available (otherwise the drawn fallback route), and the
/// technician sliding along it.
///
/// Only used when `--dart-define=GOOGLE_MAPS_API_KEY=...` is set *and* the
/// native/web key is configured (see GOOGLE_MAPS_SETUP.md). The screen shows
/// the OpenStreetMap version otherwise.
class GoogleMapView extends StatefulWidget {
  const GoogleMapView({
    super.key,
    required this.route,
    required this.directions,
    required this.technician,
    required this.technicianBearingDeg,
  });

  /// Fallback geometry + traffic bands (used when [directions] is null).
  final TrafficRoute route;

  /// Real routes from Google Directions (mobile only), or null.
  final DirectionsResult? directions;

  /// Current technician position (latlong2 space).
  final ll.LatLng technician;
  final double technicianBearingDeg;

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  gm.GoogleMapController? _controller;
  bool _framed = false;

  gm.LatLng _g(ll.LatLng p) => gm.LatLng(p.latitude, p.longitude);

  List<gm.LatLng> get _primaryPath => widget.directions != null
      ? widget.directions!.routes.first.points
      : widget.route.points.map(_g).toList();

  List<List<gm.LatLng>> get _altPaths => widget.directions != null
      ? widget.directions!.routes.skip(1).map((r) => r.points).toList()
      : widget.route.alts.map((a) => a.points.map(_g).toList()).toList();

  gm.LatLngBounds _bounds() {
    final all = <gm.LatLng>[
      ..._primaryPath,
      for (final a in _altPaths) ...a,
    ];
    var minLat = all.first.latitude, maxLat = all.first.latitude;
    var minLng = all.first.longitude, maxLng = all.first.longitude;
    for (final p in all) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    return gm.LatLngBounds(
      southwest: gm.LatLng(minLat, minLng),
      northeast: gm.LatLng(maxLat, maxLng),
    );
  }

  Future<void> _frame() async {
    if (_framed || _controller == null) return;
    _framed = true;
    await _controller!
        .animateCamera(gm.CameraUpdate.newLatLngBounds(_bounds(), 56));
  }

  @override
  void didUpdateWidget(GoogleMapView old) {
    super.didUpdateWidget(old);
    // Re-frame once real directions arrive.
    if (old.directions == null && widget.directions != null) {
      _framed = false;
      _frame();
    }
  }

  Set<gm.Polyline> _polylines() {
    final out = <gm.Polyline>{};
    for (var i = 0; i < _altPaths.length; i++) {
      out.add(gm.Polyline(
        polylineId: gm.PolylineId('alt$i'),
        points: _altPaths[i],
        color: const Color(0xFF9AA0A6),
        width: 5,
        zIndex: 1,
      ));
    }
    if (widget.directions != null) {
      out.add(gm.Polyline(
        polylineId: const gm.PolylineId('primary'),
        points: _primaryPath,
        color: const Color(0xFF1A73E8),
        width: 7,
        zIndex: 2,
      ));
    } else {
      // Fallback: colour the drawn route by our simulated traffic bands.
      for (var i = 0; i < widget.route.segments.length; i++) {
        final seg = widget.route.segments[i];
        out.add(gm.Polyline(
          polylineId: gm.PolylineId('seg$i'),
          points: seg.points.map(_g).toList(),
          color: seg.level.color,
          width: seg.level == TrafficLevel.blocked ? 8 : 7,
          zIndex: 2,
        ));
      }
    }
    return out;
  }

  Set<gm.Marker> _markers() {
    final blocked = widget.route.midpointOf(TrafficLevel.blocked);
    final unknown = widget.route.midpointOf(TrafficLevel.unknown);
    return {
      gm.Marker(
        markerId: const gm.MarkerId('origin'),
        position: _primaryPath.first,
        icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const gm.InfoWindow(title: 'Pickup'),
      ),
      gm.Marker(
        markerId: const gm.MarkerId('destination'),
        position: _primaryPath.last,
        infoWindow: const gm.InfoWindow(title: 'Destination'),
      ),
      gm.Marker(
        markerId: const gm.MarkerId('technician'),
        position: _g(widget.technician),
        rotation: widget.technicianBearingDeg,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            gm.BitmapDescriptor.hueBlue),
        infoWindow: const gm.InfoWindow(title: 'Technician'),
      ),
      if (widget.directions == null && blocked != null)
        gm.Marker(
          markerId: const gm.MarkerId('block'),
          position: _g(blocked),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueRed),
          infoWindow: const gm.InfoWindow(title: 'Road blocked'),
        ),
      if (widget.directions == null && unknown != null)
        gm.Marker(
          markerId: const gm.MarkerId('nodata'),
          position: _g(unknown),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
              gm.BitmapDescriptor.hueViolet),
          infoWindow: const gm.InfoWindow(title: 'No live traffic data'),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: _g(widget.route.center),
        zoom: widget.route.fitZoom,
      ),
      trafficEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: false,
      polylines: _polylines(),
      markers: _markers(),
      onMapCreated: (c) {
        _controller = c;
        _frame();
      },
    );
  }
}
