import 'package:latlong2/latlong.dart';

/// A technician shown on the "Nearby Technicians" live map.
class LiveTechnician {
  const LiveTechnician({
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.pos,
    this.available = true,
  });

  final String name;
  final String category;
  final double distanceKm;
  final LatLng pos;
  final bool available;

  /// Sample set scattered around central Phnom Penh, until a live API exists.
  static const sample = <LiveTechnician>[
    LiveTechnician(
        name: 'Rotha Brak',
        category: 'Car Repair',
        distanceKm: 1.6,
        pos: LatLng(11.5680, 104.9010)),
    LiveTechnician(
        name: 'Chetra Prime',
        category: 'Air Conditioner',
        distanceKm: 2.6,
        pos: LatLng(11.5620, 104.8880)),
    LiveTechnician(
        name: 'Steven',
        category: 'Electrical',
        distanceKm: 3.2,
        pos: LatLng(11.5490, 104.9160)),
    LiveTechnician(
        name: 'B Sokha',
        category: 'Motorcycle',
        distanceKm: 3.6,
        pos: LatLng(11.5780, 104.9250),
        available: false),
    LiveTechnician(
        name: 'Vanna Sok',
        category: 'Air Conditioner',
        distanceKm: 1.9,
        pos: LatLng(11.5560, 104.9070)),
  ];

  /// Where the current user is centred on the map (Phnom Penh centre).
  static const userPos = LatLng(11.5564, 104.9282);
}
