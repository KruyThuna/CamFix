import 'dart:math' as math;

import 'bookings_store.dart';

/// A cancellation-fee estimate to show the customer before they cancel.
///
/// CamFix has no payment gateway wired up anywhere in this app - nothing is
/// ever actually charged. This is a **display-only estimate** computed on the
/// device from the booking's type/status (+ distance once a technician has
/// reported a live position), so the customer knows roughly what to expect
/// before they confirm a cancellation.
class FeeEstimate {
  const FeeEstimate(
      {required this.amount, required this.noteKey, this.cancellable = true});
  final String amount;
  final String noteKey;
  final bool cancellable;
}

class CancellationFee {
  CancellationFee._();

  /// Every cancellable booking charges *something* - there is no free
  /// cancellation tier. This flat amount covers the earliest states
  /// (before a technician has started travelling); it steps up from there
  /// exactly as before (distance/time based).
  static const FeeEstimate _flatEarlyFee =
      FeeEstimate(amount: '\$1', noteKey: 'feeFlat');

  static FeeEstimate estimate(Booking b) {
    final scheduled = b.bookingType.toUpperCase() == 'SCHEDULED';
    switch (b.status) {
      case 'REQUESTED':
        return scheduled ? _scheduledTimeBased(b) : _flatEarlyFee;
      case 'ASSIGNED':
        return scheduled ? _scheduledTimeBased(b) : _flatEarlyFee;
      case 'ON_THE_WAY':
        if (!scheduled) {
          return const FeeEstimate(amount: '\$1 – \$5', noteKey: 'feeOnTheWay');
        }
        final km = _distanceKm(b);
        final amt = (5 + (km ?? 0)).clamp(5, 20);
        return FeeEstimate(amount: '\$${amt.toStringAsFixed(0)}+', noteKey: 'feeDistance');
      case 'ARRIVED':
      case 'QUOTE_PENDING':
        final km = _distanceKm(b);
        final base = scheduled ? 8.0 : 3.0;
        final perKm = scheduled ? 2.5 : 2.0;
        final cap = scheduled ? 25.0 : 15.0;
        final amt = km == null ? base : (perKm * km).clamp(base, cap);
        return FeeEstimate(amount: '\$${amt.toStringAsFixed(2)}', noteKey: 'feeDistance');
      default:
        return const FeeEstimate(
            amount: '—', noteKey: 'feeNotCancellable', cancellable: false);
    }
  }

  static FeeEstimate _scheduledTimeBased(Booking b) {
    final at = b.scheduledAt;
    if (at == null) return _flatEarlyFee;
    final hoursLeft = at.difference(DateTime.now()).inMinutes / 60.0;
    if (hoursLeft > 24) return _flatEarlyFee;
    if (hoursLeft > 2) return const FeeEstimate(amount: '\$2', noteKey: 'feeScheduledTime');
    return const FeeEstimate(amount: '\$5', noteKey: 'feeScheduledTime');
  }

  static double? _distanceKm(Booking b) {
    if (!b.hasTechnicianFix || !b.hasDestination) return null;
    return _haversineKm(
        b.technicianLat!, b.technicianLng!, b.lat!, b.lng!);
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * (math.pi / 180);
}
