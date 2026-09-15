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
    return raw.whereType<Map<String, dynamic>>().map(ServiceQuote.fromJson).toList();
  }

  Future<Booking> acceptQuote(int bookingId, int quoteId) async {
    final json = await _client.postJson(
        '/api/bookings/$bookingId/quotes/$quoteId/accept', const {},
        withAuth: true);
    return Booking.fromJson(json);
  }

  Future<Booking> rejectQuote(int bookingId, int quoteId) async {
    final json = await _client.postJson(
        '/api/bookings/$bookingId/quotes/$quoteId/reject', const {},
        withAuth: true);
    return Booking.fromJson(json);
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
