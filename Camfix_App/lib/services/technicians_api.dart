import '../models/review.dart';
import '../models/completed_work.dart';
import '../models/service_provider.dart';
import '../models/technician_service_listing.dart';
import 'api_client.dart';

/// The public technician directory (`/api/technicians/**`, no auth) - a
/// technician appears here as soon as an admin approves them.
class TechniciansApi {
  TechniciansApi._();
  static final TechniciansApi instance = TechniciansApi._();

  final _client = ApiClient.instance;

  Future<List<CompletedWork>> completedWork(int technicianId,
      {int page = 0}) async {
    final raw = await _client.getJsonList(
        '/api/technicians/$technicianId/completed-work?page=$page',
        withAuth: false);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CompletedWork.fromJson)
        .toList();
  }

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
    final raw = await _client
        .getJsonList('/api/technicians/$technicianId/reviews', withAuth: false);
    return raw.whereType<Map<String, dynamic>>().map(Review.fromJson).toList();
  }

  /// A technician's own named/priced service listings - real, technician-set
  /// data, not a fabricated per-service breakdown.
  Future<List<TechnicianServiceListing>> services(int technicianId) async {
    final raw = await _client.getJsonList(
        '/api/technicians/$technicianId/services',
        withAuth: false);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TechnicianServiceListing.fromJson)
        .toList();
  }
}
