import 'api_client.dart';

/// The "starting from" catalog price for a service category — shown before a
/// customer books, never the final repair cost (see [ServiceQuote] for that).
class ServicePriceInfo {
  const ServicePriceInfo({
    required this.categoryId,
    required this.categoryName,
    this.startingPrice,
    this.description,
  });

  final int categoryId;
  final String categoryName;
  final double? startingPrice;
  final String? description;

  factory ServicePriceInfo.fromJson(Map<String, dynamic> j) => ServicePriceInfo(
        categoryId: (j['categoryId'] as num?)?.toInt() ?? 0,
        categoryName: (j['categoryName'] ?? '').toString(),
        startingPrice: (j['startingPrice'] as num?)?.toDouble(),
        description: j['description']?.toString(),
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
