import '../models/review.dart';
import '../models/service_provider.dart';
import 'api_client.dart';

/// The public technician directory (`/api/technicians/**`, no auth) - a
/// technician appears here as soon as an admin approves them.
class TechniciansApi {
  TechniciansApi._();
  static final TechniciansApi instance = TechniciansApi._();

  final _client = ApiClient.instance;

  Future<List<ServiceProvider>> list({String? category}) async {
    final path = category == null || category.isEmpty
        ? '/api/technicians'
        : '/api/technicians?category=${Uri.encodeComponent(category)}';
    final raw = await _client.getJsonList(path, withAuth: false);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ServiceProvider.fromTechnician)
        .toList();
  }

  Future<ServiceProvider> get(int technicianId) async {
    final json = await _client.getJson('/api/technicians/$technicianId',
        withAuth: false);
    return ServiceProvider.fromTechnician(json);
  }

  Future<List<Review>> reviews(int technicianId) async {
    final raw = await _client.getJsonList(
        '/api/technicians/$technicianId/reviews',
        withAuth: false);
    return raw.whereType<Map<String, dynamic>>().map(Review.fromJson).toList();
  }
}
