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
    this.items = const [],
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

  /// Named line items the customer approves one by one (may be empty).
  final List<QuoteItem> items;

  /// Fixed fees charged regardless of item choices.
  double get feesTotal => inspectionFee + laborCost + partsCost + travelFee;

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
        items: (j['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(QuoteItem.fromJson)
            .toList(),
      );
}

/// One named item on a quote, e.g. "AC Deep Clean $15".
class QuoteItem {
  const QuoteItem({
    required this.id,
    required this.title,
    required this.price,
    this.note,
    this.recommended = false,
    this.approved,
  });

  final int id;
  final String title;
  final double price;
  final String? note;

  /// The technician recommends it (optional for the customer).
  final bool recommended;

  /// Customer decision: null until the quote is accepted.
  final bool? approved;

  factory QuoteItem.fromJson(Map<String, dynamic> j) => QuoteItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
        note: j['note']?.toString(),
        recommended: j['recommended'] == true,
        approved: j['approved'] as bool?,
      );
}
