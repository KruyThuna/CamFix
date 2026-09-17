/// A service provider / technician shown in the Services list and on the
/// provider detail screen (mockup pages 14–16).
class ServiceProvider {
  const ServiceProvider({
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
    this.technicianId,
    this.role = 'Professional',
    this.phone = '012 222 888',
    this.distanceKm = 1.6,
    this.available = true,
    this.about =
        'Experienced technician offering fast, reliable on-demand home '
            'service. Fully equipped for installation, maintenance and repair '
            'jobs across Phnom Penh.',
    this.openingHours = 'Monday - Saturday   6:00AM - 11:00PM',
    this.address = 'Phnom Penh, Hanoi Friendship Blvd, 1019, Khan Sen Sok, '
        'Phnom Penh, Cambodia',
    this.ratingCount = 470,
    this.ratingBreakdown = const [85, 9, 5, 0, 7], // % fill for 5★…1★
    this.latitude = 11.5564,
    this.longitude = 104.9282,
    this.hasLocation = true,
  });

  /// Real backend id once this card comes from `GET /api/technicians`; null
  /// for the remaining hardcoded/demo entries elsewhere in the app (booking
  /// still works for those - it just isn't assigned to a specific technician).
  final int? technicianId;

  final String name;
  final String category;
  final String location;
  final double rating;
  final String role;
  final String phone;
  final double distanceKm;
  final bool available;
  final String about;
  final String openingHours;
  final String address;

  /// Approximate shop location, for the map preview on the detail screen.
  /// Falls back to the Phnom Penh centre point when [hasLocation] is false -
  /// check that flag before trusting these as a real position (e.g. before
  /// dropping a "you'll find them here" pin on a map).
  final double latitude;
  final double longitude;

  /// Whether [latitude]/[longitude] are a real reported position rather than
  /// the fallback centre point. `GET /api/technicians` returns null lat/lng
  /// for a technician who has never gone online - true for both technicians
  /// in this project's seed data.
  final bool hasLocation;

  /// Total number of ratings received (shown under the average score).
  final int ratingCount;

  /// Bar fill percentage (0–100) for each star level, highest first:
  /// [5★, 4★, 3★, 2★, 1★].
  final List<int> ratingBreakdown;

  factory ServiceProvider.fromTechnician(Map<String, dynamic> j) {
    final rating = (j['rating'] as num?)?.toDouble() ?? 0;
    final count = (j['ratingCount'] as num?)?.toInt() ?? 0;
    return ServiceProvider(
      technicianId: (j['id'] as num?)?.toInt(),
      name: (j['name'] as String?)?.trim().isNotEmpty == true
          ? j['name'] as String
          : 'CAM FIX technician',
      category: j['category']?.toString() ?? '',
      location: j['serviceArea']?.toString() ?? '',
      rating: rating,
      ratingCount: count,
      phone: j['phone']?.toString() ?? '',
      available: j['available'] == true,
      about: (j['about'] as String?)?.trim().isNotEmpty == true
          ? j['about'] as String
          : 'This technician hasn\'t added a description yet.',
      openingHours: j['openingHours']?.toString() ?? '—',
      address: j['serviceArea']?.toString() ?? '—',
      // Bar breakdown isn't tracked per-star server-side yet - approximate a
      // single bucket at the rounded average so the chart isn't empty.
      ratingBreakdown: count == 0
          ? const [0, 0, 0, 0, 0]
          : List.generate(5, (i) => i == (5 - rating.round()).clamp(0, 4) ? 100 : 0),
      latitude: (j['lat'] as num?)?.toDouble() ?? 11.5564,
      longitude: (j['lng'] as num?)?.toDouble() ?? 104.9282,
      hasLocation: j['lat'] != null && j['lng'] != null,
    );
  }
}
