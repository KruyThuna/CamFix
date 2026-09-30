/// One version of an itemized repair quote for a job, from
/// `/api/technician/me/jobs/{id}/quotes`.
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

  /// Named line items; after acceptance each carries the customer's decision.
  final List<QuoteItem> items;

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

/// One named line item on a quote.
class QuoteItem {
  const QuoteItem({
    required this.title,
    required this.price,
    this.note,
    this.recommended = false,
    this.approved,
  });

  final String title;
  final double price;
  final String? note;
  final bool recommended;

  /// Customer's decision: true = do it, false = declined, null = undecided.
  final bool? approved;

  factory QuoteItem.fromJson(Map<String, dynamic> j) => QuoteItem(
        title: (j['title'] ?? '').toString(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
        note: j['note']?.toString(),
        recommended: j['recommended'] == true,
        approved: j['approved'] as bool?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        if (note != null && note!.isNotEmpty) 'note': note,
        'recommended': recommended,
      };
}
