import '../models/app_banner.dart';
import 'api_client.dart';

class BannerApi {
  BannerApi._();
  static final BannerApi instance = BannerApi._();

  final _client = ApiClient.instance;

  /// Fetches all active promotional banners for the Home/Dashboard carousel.
  Future<List<AppBanner>> list() async {
    try {
      final raw = await _client.getJsonList('/api/banners');
      return raw.map((j) => AppBanner.fromJson(j)).toList();
    } catch (_) {
      return const [];
    }
  }
}
