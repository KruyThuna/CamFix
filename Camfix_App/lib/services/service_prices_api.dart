import 'api_client.dart';

/// The "starting from" catalog price for a service category — shown before a
/// customer books, never the final repair cost (see [ServiceQuote] for that).
class ServicePriceInfo {
  const ServicePriceInfo({
    required this.categoryId,
    required this.categoryName,
    this.startingPrice,
    this.description,
    this.rating = 0,
    this.ratingCount = 0,
    this.bookingCount = 0,
    this.photoUrl,
    this.benchFee,
    this.travelFee,
  });

  /// Self Drop diagnostic fee, paid at drop-off - admin-set, null when the
  /// admin hasn't configured one (the app then shows no bench-fee line).
  final double? benchFee;

  /// Standard home-visit travel fee - admin-set, null when not configured.
  /// Self Drop bookings never pay it (the backend zeroes it on the quote).
  final double? travelFee;

  final int categoryId;
  final String categoryName;
  final double? startingPrice;
  final String? description;

  /// Weighted average rating across this category's approved technicians —
  /// a real aggregate from `Technician.averageRating`, 0 when none rated yet.
  final double rating;

  /// Sum of ratings behind [rating].
  final int ratingCount;

  /// Real completed-job count for this category.
  final int bookingCount;

  /// A representative technician's photo in this category, if any has one.
  final String? photoUrl;

  factory ServicePriceInfo.fromJson(Map<String, dynamic> j) => ServicePriceInfo(
        categoryId: (j['categoryId'] as num?)?.toInt() ?? 0,
        categoryName: (j['categoryName'] ?? '').toString(),
        startingPrice: (j['startingPrice'] as num?)?.toDouble(),
        description: j['description']?.toString(),
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        bookingCount: (j['bookingCount'] as num?)?.toInt() ?? 0,
        photoUrl: j['photoUrl']?.toString(),
        benchFee: (j['benchFee'] as num?)?.toDouble(),
        travelFee: (j['travelFee'] as num?)?.toDouble(),
      );
}

/// `GET /api/service-prices` — public, no auth required.
class ServicePricesApi {
  ServicePricesApi._();
  static final ServicePricesApi instance = ServicePricesApi._();

  final _client = ApiClient.instance;
  List<ServicePriceInfo>? _cache;

  Future<List<ServicePriceInfo>> list({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final raw = await _client.getJsonList('/api/service-prices', withAuth: false);
    _cache = raw.whereType<Map<String, dynamic>>().map(ServicePriceInfo.fromJson).toList();
    return _cache!;
  }

  /// The whole catalog row for a category (starting price + fees), or null.
  Future<ServicePriceInfo?> infoFor(String categoryName) async {
    try {
      final prices = await list(forceRefresh: true);
      for (final p in prices) {
        if (p.categoryName == categoryName) return p;
      }
    } catch (_) {
      // pricing not configured or offline - booking still works without it
    }
    return null;
  }

  /// Best-effort lookup by category name; null if pricing isn't loaded/configured.
  Future<double?> startingPriceFor(String categoryName) async {
    try {
      final prices = await list();
      for (final p in prices) {
        if (p.categoryName == categoryName) return p.startingPrice;
      }
    } catch (_) {
      // no pricing configured yet, or offline — booking still works without it
    }
    return null;
  }
}
