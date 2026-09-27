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
    this.bookingType = 'IMMEDIATE',
    this.benchFee,
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
  final String status; // ASSIGNED | ON_THE_WAY | ARRIVED | QUOTE_PENDING | IN_PROGRESS | COMPLETED | CANCELLED
  /// IMMEDIATE | SCHEDULED | SELF_DROP.
  final String bookingType;

  /// Self Drop only: admin-set diagnostic fee locked in at booking time. The
  /// backend forces it as the quote's inspection fee and zeroes travel.
  final double? benchFee;

  /// The customer brings the item to the technician - [address]/[lat]/[lng]
  /// are the technician's own shop, not somewhere to drive to.
  bool get isSelfDrop => bookingType == 'SELF_DROP';

  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;

  bool get isActive => status != 'COMPLETED' && status != 'CANCELLED';

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
    bookingType: (j['bookingType'] ?? 'IMMEDIATE').toString(),
    benchFee: (j['benchFee'] as num?)?.toDouble(),
    createdAt: _date(j['createdAt']),
    scheduledAt: _date(j['scheduledAt']),
    assignedAt: _date(j['assignedAt']),
    completedAt: _date(j['completedAt']),
  );
}
