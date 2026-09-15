/// A logged phone call between the customer and a technician, from
/// `POST/GET /api/calls/**`.
class CallRecord {
  const CallRecord({
    required this.callId,
    required this.technicianId,
    required this.callStatus,
    this.durationSeconds = 0,
  });

  final int callId;
  final int technicianId;
  final String callStatus; // ONGOING | COMPLETED
  final int durationSeconds;

  factory CallRecord.fromJson(Map<String, dynamic> j) => CallRecord(
        callId: (j['callId'] as num?)?.toInt() ?? 0,
        technicianId: (j['technicianId'] as num?)?.toInt() ?? 0,
        callStatus: (j['callStatus'] ?? 'ONGOING').toString(),
        durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
      );
}
