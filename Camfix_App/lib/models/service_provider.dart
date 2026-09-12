/// A service provider / technician shown in the Services list and on the
/// provider detail screen (mockup pages 14–16).
class ServiceProvider {
  const ServiceProvider({
    required this.name,
    required this.category,
    required this.location,
    required this.rating,
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
  });

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
  final double latitude;
  final double longitude;

  /// Total number of ratings received (shown under the average score).
  final int ratingCount;

  /// Bar fill percentage (0–100) for each star level, highest first:
  /// [5★, 4★, 3★, 2★, 1★].
  final List<int> ratingBreakdown;
}
