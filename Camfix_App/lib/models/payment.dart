/// A mock payment against an accepted [ServiceQuote], from
/// `POST /api/bookings/{id}/quotes/{quoteId}/pay`. No real card processor is
/// wired up in this project - this just records that the customer "paid".
class Payment {
  const Payment({
    required this.jobId,
    required this.quoteId,
    required this.baseAmount,
    required this.platformFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    this.cardLast4,
    required this.serviceRef,
    this.createdAt,
  });

  final int jobId;
  final int quoteId;
  final double baseAmount;
  final double platformFee;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod; // APPLE_PAY | CARD | PAYPAL
  final String? cardLast4;
  final String serviceRef;
  final DateTime? createdAt;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        jobId: (j['jobId'] as num?)?.toInt() ?? 0,
        quoteId: (j['quoteId'] as num?)?.toInt() ?? 0,
        baseAmount: (j['baseAmount'] as num?)?.toDouble() ?? 0,
        platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0,
        taxAmount: (j['taxAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        paymentMethod: (j['paymentMethod'] ?? '').toString(),
        cardLast4: j['cardLast4']?.toString(),
        serviceRef: (j['serviceRef'] ?? '').toString(),
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'].toString())?.toLocal(),
      );
}
