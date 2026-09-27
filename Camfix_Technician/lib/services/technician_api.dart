import '../models/service_quote.dart';
import '../models/tech_job.dart';
import '../models/tech_service_listing.dart';
import '../models/technician_profile.dart';
import 'api_client.dart';

/// Calls against the technician self-service surface (`/api/technician/**`).
class TechnicianApi {
  TechnicianApi._();
  static final TechnicianApi instance = TechnicianApi._();

  final _client = ApiClient.instance;

  Future<TechnicianProfile> me({Duration ttl = Duration.zero}) async {
    final json = await _client.getJson('/api/technician/me', ttl: ttl);
    return TechnicianProfile.fromJson(json);
  }

  Future<TechnicianProfile> updateProfile(Map<String, dynamic> fields) async {
    final json = await _client.putJson('/api/technician/me', fields);
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  Future<TechnicianProfile> setAvailability(bool available) async {
    final json = await _client.patchJson('/api/technician/me/availability', {
      'available': available,
    });
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  Future<TechnicianProfile> uploadPhoto(
    List<int> bytes, {
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final json = await _client.postMultipart(
      '/api/technician/me/photo',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  Future<TechnicianProfile> deletePhoto() async {
    final json = await _client.deleteJson('/api/technician/me/photo');
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  /// Promotional banner shown to customers in the app's home carousel -
  /// separate from [uploadPhoto] (the technician's own profile picture).
  Future<TechnicianProfile> uploadBanner(
    List<int> bytes, {
    String filename = 'banner.jpg',
    String contentType = 'image/jpeg',
    String? title,
  }) async {
    final json = await _client.postMultipart(
      '/api/technician/me/banner',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      fields: title == null || title.isEmpty ? null : {'title': title},
    );
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  Future<TechnicianProfile> deleteBanner() async {
    final json = await _client.deleteJson('/api/technician/me/banner');
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  Future<void> pushLocation(double lat, double lng) => _client.patchJson(
    '/api/technician/me/location',
    {'lat': lat, 'lng': lng},
  );

  Future<List<TechJob>> myJobs({String? status}) async {
    final path = status == null
        ? '/api/technician/me/jobs'
        : '/api/technician/me/jobs?status=$status';
    final res = await _client.getJsonList(path);
    return res.map((e) => TechJob.fromJson(e)).toList();
  }

  Future<TechJob> job(int id) async {
    final json = await _client.getJson('/api/technician/me/jobs/$id');
    return TechJob.fromJson(json);
  }

  Future<TechJob> setJobStatus(int id, String status) async {
    final json = await _client.postJson('/api/technician/me/jobs/$id/status', {
      'status': status,
    }, withAuth: true);
    return TechJob.fromJson(json);
  }

  /// Submits (or revises) an itemized repair quote for a job the technician
  /// has arrived at. The job moves to QUOTE_PENDING; the customer decides.
  Future<ServiceQuote> submitQuote(
    int jobId, {
    required double inspectionFee,
    required double laborCost,
    required double partsCost,
    required double travelFee,
    String? reason,
    List<QuoteItem> items = const [],
  }) async {
    final json = await _client.postJson(
      '/api/technician/me/jobs/$jobId/quotes',
      {
        'inspectionFee': inspectionFee,
        'laborCost': laborCost,
        'partsCost': partsCost,
        'travelFee': travelFee,
        'reason': ?reason,
        if (items.isNotEmpty) 'items': [for (final i in items) i.toJson()],
      },
      withAuth: true,
    );
    return ServiceQuote.fromJson(json);
  }

  Future<List<ServiceQuote>> jobQuotes(int jobId) async {
    final res = await _client.getJsonList(
      '/api/technician/me/jobs/$jobId/quotes',
    );
    return res.map(ServiceQuote.fromJson).toList();
  }

  // --- Own named/priced service listings -----------------------------------

  Future<List<TechServiceListing>> myServices() async {
    final res = await _client.getJsonList('/api/technician/me/services');
    return res.map(TechServiceListing.fromJson).toList();
  }

  Future<TechServiceListing> createService(
    String title,
    double price,
    String? description,
  ) async {
    final json = await _client.postJson('/api/technician/me/services', {
      'title': title,
      'price': price,
      'description': description,
    }, withAuth: true);
    return TechServiceListing.fromJson(json);
  }

  Future<TechServiceListing> updateService(
    int id,
    String title,
    double price,
    String? description,
  ) async {
    final json = await _client.putJson('/api/technician/me/services/$id', {
      'title': title,
      'price': price,
      'description': description,
    });
    return TechServiceListing.fromJson(json);
  }

  /// Attach / replace the photo customers see on this listing.
  Future<TechServiceListing> uploadServicePhoto(
    int id,
    List<int> bytes, {
    String filename = 'service.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final json = await _client.postMultipart(
      '/api/technician/me/services/$id/photo',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return TechServiceListing.fromJson(json);
  }

  Future<void> deleteServicePhoto(int id) =>
      _client.deleteJson('/api/technician/me/services/$id/photo');

  Future<void> deleteService(int id) =>
      _client.deleteJson('/api/technician/me/services/$id');
}
