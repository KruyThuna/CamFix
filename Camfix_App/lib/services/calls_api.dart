import '../models/call_record.dart';
import 'api_client.dart';

/// Logs phone calls between the customer and a technician (`/api/calls/**`)
/// so a call actually leaves a record instead of just opening the dialer.
class CallsApi {
  CallsApi._();
  static final CallsApi instance = CallsApi._();

  final _client = ApiClient.instance;

  Future<CallRecord> start(int technicianId) async {
    final json = await _client.postJson(
        '/api/calls/start', {'technicianId': technicianId},
        withAuth: true);
    return CallRecord.fromJson(json);
  }

  Future<CallRecord> end(int callId) async {
    final json =
        await _client.putJson('/api/calls/$callId/end', const {});
    return CallRecord.fromJson(json);
  }
}
