import '../models/payment.dart';
import '../models/review.dart';
import '../models/service_quote.dart';
import '../services/bookings_store.dart' show Booking;
import 'api_client.dart';

/// Calls against the signed-in customer's bookings (`/api/bookings/**`).
class BookingsApi {
  BookingsApi._();
  static final BookingsApi instance = BookingsApi._();

  final _client = ApiClient.instance;

  Future<List<Booking>> listMine() async {
    final raw = await _client.getJsonList('/api/bookings/mine');
    return raw.whereType<Map<String, dynamic>>().map(Booking.fromJson).toList();
  }

  Future<Booking> getOne(int id) async {
    final json = await _client.getJson('/api/bookings/$id');
    return Booking.fromJson(json);
  }

  Future<Booking> cancel(int id) async {
    final json = await _client.postJson('/api/bookings/$id/cancel', const {},
        withAuth: true);
    return Booking.fromJson(json);
  }

  /// Full quote history for a booking, latest version first.
  Future<List<ServiceQuote>> quotes(int bookingId) async {
    final raw = await _client.getJsonList('/api/bookings/$bookingId/quotes');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ServiceQuote.fromJson)
        .toList();
  }

  /// Accept a quote. [approvedItemIds] = the line items the customer
  /// ticked (null approves every item); only those are done and paid for.
  Future<Booking> acceptQuote(int bookingId, int quoteId,
      {List<int>? approvedItemIds}) async {
    final json = await _client.postJson(
        '/api/bookings/$bookingId/quotes/$quoteId/accept',
        {if (approvedItemIds != null) 'approvedItemIds': approvedItemIds},
        withAuth: true);
    return Booking.fromJson(json);
  }

  // --- KHQR (Bakong) ---------------------------------------------------------

  /// Whether the server has Bakong KHQR configured.
  Future<bool> khqrEnabled() async {
    try {
      final json =
          await _client.getJson('/api/bookings/khqr/config', withAuth: false);
      return json['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Generate a KHQR for an accepted quote (amount incl. platform fee + tax).
  Future<Map<String, dynamic>> startKhqr(int bookingId, int quoteId) =>
      _client.postJson(
          '/api/bookings/$bookingId/quotes/$quoteId/khqr', const {},
          withAuth: true);

  /// PENDING / PAID (with payment) / EXPIRED.
  Future<Map<String, dynamic>> khqrStatus(int bookingId, String md5) =>
      _client.getJson('/api/bookings/$bookingId/khqr/$md5');

  Future<Booking> rejectQuote(int bookingId, int quoteId) async {
    final json = await _client.postJson(
        '/api/bookings/$bookingId/quotes/$quoteId/reject', const {},
        withAuth: true);
    return Booking.fromJson(json);
  }

  /// Real sum across every payment the signed-in customer has made, for the
  /// profile screen's "Total Spend" stat.
  Future<double> myTotalSpend() async {
    final json = await _client.getJson('/api/bookings/payments/mine');
    return (json['totalSpend'] as num?)?.toDouble() ?? 0;
  }

  /// Mock payment for an already-accepted quote. Paying again for the same
  /// quote returns the original payment rather than charging twice.
  Future<Payment> payQuote(
    int bookingId,
    int quoteId, {
    required String paymentMethod,
    String? cardLast4,
  }) async {
    final json = await _client.postJson(
      '/api/bookings/$bookingId/quotes/$quoteId/pay',
      {
        'paymentMethod': paymentMethod,
        if (cardLast4 != null) 'cardLast4': cardLast4,
      },
      withAuth: true,
    );
    return Payment.fromJson(json);
  }

  /// Every payment the signed-in customer has made, newest first.
  Future<List<Payment>> myPayments() async {
    final json = await _client.getJson('/api/bookings/payments/mine');
    final list = json['payments'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Payment.fromJson)
        .toList();
  }

  /// The payment recorded for this booking, or `null` if it hasn't been paid.
  Future<Payment?> payment(int bookingId) async {
    final json = await _client.getJson('/api/bookings/$bookingId/payment');
    if (json.isEmpty || json['serviceRef'] == null) return null;
    return Payment.fromJson(json);
  }

  /// The customer's own review for this booking, or `null` if not left yet.
  Future<Review?> myReview(int bookingId) async {
    final json = await _client.getJson('/api/bookings/$bookingId/review');
    if (json.isEmpty || json['id'] == null) return null;
    return Review.fromJson(json);
  }

  Future<Review> submitReview(int bookingId,
      {required int rating, String? comment}) async {
    final json = await _client.postJson(
      '/api/bookings/$bookingId/review',
      {'rating': rating, if (comment != null) 'comment': comment},
      withAuth: true,
    );
    return Review.fromJson(json);
  }
}
