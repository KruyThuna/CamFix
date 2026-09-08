import '../models/tech_job.dart';
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
    final json = await _client
        .patchJson('/api/technician/me/availability', {'available': available});
    _client.invalidate('/api/technician/me');
    return TechnicianProfile.fromJson(json);
  }

  Future<void> pushLocation(double lat, double lng) =>
      _client.patchJson('/api/technician/me/location', {'lat': lat, 'lng': lng});

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
    final json = await _client.postJson(
        '/api/technician/me/jobs/$id/status', {'status': status},
        withAuth: true);
    return TechJob.fromJson(json);
  }
}
