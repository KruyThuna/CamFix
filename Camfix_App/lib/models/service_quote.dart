/// One version of a technician's itemized repair quote for a booking, from
/// `GET /api/bookings/{id}/quotes`. A booking can have several — each new
/// version supersedes the previous PENDING one (which becomes `REVISED`).
class ServiceQuote {
  const ServiceQuote({
    required this.id,
    required this.jobId,
    required this.technicianId,
    required this.version,
    required this.inspectionFee,
    required this.laborCost,
    required this.partsCost,
    required this.travelFee,
    required this.totalAmount,
    this.reason,
    required this.status,
    this.createdAt,
  });

  final int id;
  final int jobId;
  final int technicianId;
  final int version;
  final double inspectionFee;
  final double laborCost;
  final double partsCost;
  final double travelFee;
  final double totalAmount;
  final String? reason;
  final String status; // PENDING | ACCEPTED | REJECTED | REVISED | EXPIRED
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';

  factory ServiceQuote.fromJson(Map<String, dynamic> j) => ServiceQuote(
        id: (j['id'] as num?)?.toInt() ?? 0,
        jobId: (j['jobId'] as num?)?.toInt() ?? 0,
        technicianId: (j['technicianId'] as num?)?.toInt() ?? 0,
        version: (j['version'] as num?)?.toInt() ?? 1,
        inspectionFee: (j['inspectionFee'] as num?)?.toDouble() ?? 0,
        laborCost: (j['laborCost'] as num?)?.toDouble() ?? 0,
        partsCost: (j['partsCost'] as num?)?.toDouble() ?? 0,
        travelFee: (j['travelFee'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        reason: j['reason']?.toString(),
        status: (j['status'] ?? 'PENDING').toString(),
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString())?.toLocal(),
      );
}
