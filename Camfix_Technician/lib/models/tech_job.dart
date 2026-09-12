/// A job assigned to the signed-in technician, from `/api/technician/me/jobs`.
class TechJob {
  const TechJob({
    required this.id,
    this.customerName = '',
    this.customerPhone = '',
    this.category = '',
    this.description = '',
    this.address,
    this.lat,
    this.lng,
    this.status = 'ASSIGNED',
    this.createdAt,
    this.scheduledAt,
    this.assignedAt,
    this.completedAt,
  });

  final int id;
  final String customerName;
  final String customerPhone;
  final String category;
  final String description;
  final String? address;
  final double? lat;
  final double? lng;
  final String status; // REQUESTED | ASSIGNED | IN_PROGRESS | COMPLETED | CANCELLED
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  bool get isActive => status == 'ASSIGNED' || status == 'IN_PROGRESS';

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory TechJob.fromJson(Map<String, dynamic> j) => TechJob(
        id: (j['id'] as num?)?.toInt() ?? 0,
        customerName: (j['customerName'] ?? '').toString(),
        customerPhone: (j['customerPhone'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        address: j['address']?.toString(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        status: (j['status'] ?? 'ASSIGNED').toString(),
        createdAt: _date(j['createdAt']),
        scheduledAt: _date(j['scheduledAt']),
        assignedAt: _date(j['assignedAt']),
        completedAt: _date(j['completedAt']),
      );
}
