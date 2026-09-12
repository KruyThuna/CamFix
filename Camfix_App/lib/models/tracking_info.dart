import 'package:latlong2/latlong.dart';

/// The data behind the "Tracking Details" sheet + live map (mockup pages 27–31).
class TrackingInfo {
  const TrackingInfo({
    required this.serviceKey,
    required this.trackingId,
    required this.originName,
    required this.destinationName,
    required this.technicianName,
    required this.rating,
    required this.currentStep,
    required this.origin,
    required this.destination,
    required this.technicianPos,
  });

  /// i18n key for the service name, e.g. `svcAirConditioner`.
  final String serviceKey;
  final String trackingId;
  final String originName;
  final String destinationName;
  final String technicianName;
  final double rating;

  /// 0 = Booked, 1 = In Transit, 2 = Processing, 3 = Completed.
  final int currentStep;

  final LatLng origin;
  final LatLng destination;
  final LatLng technicianPos;

  /// Sample job matching the mockup, used until a real jobs API exists.
  static const sample = TrackingInfo(
    serviceKey: 'svcAirConditioner',
    trackingId: '1111111112',
    originName: 'SenSok',
    destinationName: 'ToulKouk',
    technicianName: 'Vanna Sok',
    rating: 4.5,
    currentStep: 1,
    origin: LatLng(11.5900, 104.8900),
    destination: LatLng(11.5680, 104.8960),
    technicianPos: LatLng(11.5790, 104.8925),
  );
}
