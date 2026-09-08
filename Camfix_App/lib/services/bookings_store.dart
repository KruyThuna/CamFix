import 'package:flutter/foundation.dart';

enum BookingStatus { upcoming, completed }

/// One service booking the customer made.
class Booking {
  Booking({
    required this.provider,
    required this.service,
    required this.category,
    required this.when,
    required this.address,
    this.status = BookingStatus.upcoming,
  });

  final String provider;
  final String service; // Repair / Clean / …
  final String category; // Air Conditioner / Car / …
  final DateTime when;
  final String address; // "lat, lng" or a typed address
  BookingStatus status;

  /// "Today 2:30 PM" / "Jun 26  2:30 PM".
  String get whenLabel {
    final now = DateTime.now();
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final m = when.minute.toString().padLeft(2, '0');
    final ampm = when.hour < 12 ? 'AM' : 'PM';
    final time = '$h:$m $ampm';
    final sameDay = when.year == now.year &&
        when.month == now.month &&
        when.day == now.day;
    if (sameDay) return 'Today   $time';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[when.month - 1]} ${when.day}   $time';
  }
}

/// In‑memory list of the customer's bookings. New bookings land in [upcoming]
/// (shown on the dashboard "Active Job" tab); [completed] feeds "History".
/// Seeded with the sample rows the mockups show.
class BookingsStore extends ChangeNotifier {
  BookingsStore._() {
    _all.addAll([
      Booking(
        provider: 'Vanna Sok',
        service: 'Repair',
        category: 'Air Conditioner',
        when: DateTime.now().copyWith(hour: 14, minute: 30),
        address: '11.556400, 104.928200',
      ),
      Booking(
        provider: 'Vanna Sok',
        service: 'Clean',
        category: 'Air Conditioner',
        when: DateTime(2026, 6, 26, 14, 30),
        address: 'SenSok, Phnom Penh',
        status: BookingStatus.completed,
      ),
    ]);
  }
  static final BookingsStore instance = BookingsStore._();

  final List<Booking> _all = [];

  List<Booking> get upcoming =>
      _all.where((b) => b.status == BookingStatus.upcoming).toList();
  List<Booking> get completed =>
      _all.where((b) => b.status == BookingStatus.completed).toList();

  void add(Booking b) {
    _all.insert(0, b);
    notifyListeners();
  }
}
