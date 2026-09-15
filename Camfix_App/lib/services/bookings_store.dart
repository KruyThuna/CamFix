import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bookings_api.dart';

const _openStatuses = {
  'REQUESTED',
  'ASSIGNED',
  'ON_THE_WAY',
  'ARRIVED',
  'QUOTE_PENDING',
  'IN_PROGRESS',
};

/// One of the customer's bookings, as returned by `GET /api/bookings/mine`.
class Booking {
  const Booking({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    this.bookingType = 'IMMEDIATE',
    this.startingPrice,
    this.address,
    this.lat,
    this.lng,
    this.scheduledAt,
    this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.technicianId,
    this.technicianName,
    this.technicianPhone,
    this.technicianLat,
    this.technicianLng,
    this.technicianLocationAt,
  });

  final int id;
  final String category;
  final String description;
  final String status; // REQUESTED | ASSIGNED | ON_THE_WAY | ARRIVED | IN_PROGRESS | COMPLETED | CANCELLED
  final String bookingType; // IMMEDIATE | SCHEDULED
  /// "Starting from" price snapshotted when this booking was made — NOT the
  /// final repair cost. Null if no catalog price was configured for the
  /// category at booking time.
  final double? startingPrice;
  final String? address;
  final double? lat;
  final double? lng;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final int? technicianId;
  final String? technicianName;
  final String? technicianPhone;
  final double? technicianLat;
  final double? technicianLng;
  final DateTime? technicianLocationAt;

  bool get isOpen => _openStatuses.contains(status);
  bool get isCancellable => const {
        'REQUESTED', 'ASSIGNED', 'ON_THE_WAY', 'ARRIVED', 'QUOTE_PENDING',
      }.contains(status);
  bool get hasTechnicianFix => technicianLat != null && technicianLng != null;
  bool get hasDestination => lat != null && lng != null;

  /// The moment this booking is "for" — when scheduled, or when it was made.
  DateTime get when => scheduledAt ?? createdAt ?? DateTime.now();

  /// "Today 2:30 PM" / "Jun 26  2:30 PM".
  String get whenLabel {
    final now = DateTime.now();
    final t = when;
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    final time = '$h:$m $ampm';
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) return 'Today   $time';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[t.month - 1]} ${t.day}   $time';
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: (j['id'] as num?)?.toInt() ?? 0,
        category: (j['category'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        status: (j['status'] ?? 'REQUESTED').toString(),
        bookingType: (j['bookingType'] ?? 'IMMEDIATE').toString(),
        startingPrice: (j['startingPrice'] as num?)?.toDouble(),
        address: j['address']?.toString(),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        scheduledAt: _date(j['scheduledAt']),
        createdAt: _date(j['createdAt']),
        assignedAt: _date(j['assignedAt']),
        completedAt: _date(j['completedAt']),
        technicianId: (j['technicianId'] as num?)?.toInt(),
        technicianName: j['technicianName']?.toString(),
        technicianPhone: j['technicianPhone']?.toString(),
        technicianLat: (j['technicianLat'] as num?)?.toDouble(),
        technicianLng: (j['technicianLng'] as num?)?.toDouble(),
        technicianLocationAt: _date(j['technicianLocationAt']),
      );
}

/// The customer's bookings, polled from the backend. [upcoming] (not yet
/// completed/cancelled) feeds the dashboard "Active Job" tab; [completed]
/// (completed or cancelled) feeds "History".
class BookingsStore extends ChangeNotifier {
  BookingsStore._();
  static final BookingsStore instance = BookingsStore._();

  List<Booking> _all = const [];
  bool _loading = false;
  Timer? _poll;

  List<Booking> get upcoming => _all.where((b) => b.isOpen).toList();
  List<Booking> get completed => _all.where((b) => !b.isOpen).toList();
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _all = await BookingsApi.instance.listMine();
    } catch (_) {
      // keep whatever we had; a transient error shouldn't blank the list
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void startPolling([Duration interval = const Duration(seconds: 20)]) {
    _poll?.cancel();
    unawaited(refresh());
    _poll = Timer.periodic(interval, (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  void clear() {
    stopPolling();
    _all = const [];
    notifyListeners();
  }
}
