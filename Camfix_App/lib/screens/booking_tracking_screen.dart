import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/review.dart';
import '../models/service_quote.dart';
import '../services/bookings_api.dart';
import '../services/calls_api.dart';
import '../services/favorites_api.dart';
import '../services/bookings_store.dart';
import '../services/cancellation_fee.dart';
import '../services/osrm_api.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

const _steps = [
  'REQUESTED', 'ASSIGNED', 'ON_THE_WAY', 'ARRIVED', 'QUOTE_PENDING', 'IN_PROGRESS', 'COMPLETED',
];
const _stepKeys = {
  'REQUESTED': 'stepPending',
  'ASSIGNED': 'stepAccepted',
  'ON_THE_WAY': 'stepOnTheWay',
  'ARRIVED': 'stepArrived',
  'QUOTE_PENDING': 'stepQuotePending',
  'IN_PROGRESS': 'stepInProgress',
  'COMPLETED': 'stepCompleted',
};

/// Shows a booking's live status once a technician is involved: a map with
/// the technician's last reported GPS fix + the job address, a status
/// timeline, and (while still cancellable) an estimated cancellation fee.
/// Polls `GET /api/bookings/{id}` every few seconds for real updates.
class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({super.key});

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen>
    with WidgetsBindingObserver {
  int? _id;
  Booking? _booking;
  String? _loadError;
  bool _cancelling = false;
  Timer? _poll;
  int? _activeCallId;

  List<ServiceQuote> _quotes = const [];
  bool _decidingQuote = false;

  Review? _review;
  int _pendingStars = 0;
  bool _submittingReview = false;
  final _reviewComment = TextEditingController();

  bool? _isFavoriteTechnician;
  bool _favoriteBusy = false;

  OsrmResult? _osrm;
  LatLng? _routedFrom;
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_id != null) return;
    _id = ModalRoute.of(context)!.settings.arguments as int;
    _load();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _reviewComment.dispose();
    super.dispose();
  }

  /// Returning to the app after the OS phone dialer closes is the closest
  /// signal we have (no call-state API) that the call just ended - end the
  /// logged call here so it gets a real duration.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeCallId != null) {
      final id = _activeCallId!;
      _activeCallId = null;
      unawaited(CallsApi.instance.end(id));
    }
  }

  Future<void> _load() async {
    try {
      final b = await BookingsApi.instance.getOne(_id!);
      if (!mounted) return;
      setState(() {
        _booking = b;
        _loadError = null;
      });
      if (!b.isOpen) _poll?.cancel(); // terminal state - stop polling
      unawaited(_maybeRefreshRoute(b));
      unawaited(_loadQuotes());
      if (b.status == 'COMPLETED') unawaited(_loadReview());
      if (b.technicianId != null && _isFavoriteTechnician == null) {
        unawaited(_loadFavoriteStatus(b.technicianId!));
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _loadFavoriteStatus(int technicianId) async {
    try {
      final fav = await FavoritesApi.instance.check(technicianId);
      if (mounted) setState(() => _isFavoriteTechnician = fav);
    } catch (_) {
      // favorite status is a nice-to-have; don't blank the whole screen for it
    }
  }

  Future<void> _toggleFavorite(int technicianId) async {
    final current = _isFavoriteTechnician ?? false;
    setState(() {
      _isFavoriteTechnician = !current;
      _favoriteBusy = true;
    });
    try {
      if (current) {
        await FavoritesApi.instance.remove(technicianId);
      } else {
        await FavoritesApi.instance.add(technicianId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppStrings.t(
                current ? 'removedFromFavorites' : 'addedToFavorites'))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavoriteTechnician = current); // revert on failure
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _loadReview() async {
    try {
      final r = await BookingsApi.instance.myReview(_id!);
      if (mounted) setState(() => _review = r);
    } catch (_) {
      // review status is a nice-to-have; don't blank the whole screen for it
    }
  }

  Future<void> _submitReview() async {
    if (_pendingStars < 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.t('reviewRequired'))));
      return;
    }
    setState(() => _submittingReview = true);
    try {
      final comment = _reviewComment.text.trim();
      final review = await BookingsApi.instance.submitReview(_id!,
          rating: _pendingStars, comment: comment.isEmpty ? null : comment);
      if (mounted) {
        setState(() => _review = review);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('reviewSubmittedThanks'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  Future<void> _loadQuotes() async {
    try {
      final quotes = await BookingsApi.instance.quotes(_id!);
      if (mounted) setState(() => _quotes = quotes);
    } catch (_) {
      // quote history is a nice-to-have; don't blank the whole screen for it
    }
  }

  Future<void> _decideQuote(ServiceQuote q, {required bool accept}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t(
            accept ? 'quoteAcceptConfirmTitle' : 'quoteRejectConfirmTitle')),
        content: Text(AppStrings.t(
            accept ? 'quoteAcceptConfirmMessage' : 'quoteRejectConfirmMessage')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: accept
                  ? null
                  : FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(AppStrings.t(accept ? 'quoteAccept' : 'quoteReject'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _decidingQuote = true);
    try {
      final updated = accept
          ? await BookingsApi.instance.acceptQuote(_id!, q.id)
          : await BookingsApi.instance.rejectQuote(_id!, q.id);
      if (mounted) setState(() => _booking = updated);
      unawaited(_loadQuotes());
      unawaited(BookingsStore.instance.refresh());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppStrings.t(accept ? 'quoteAccepted' : 'quoteRejected'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _decidingQuote = false);
    }
  }

  /// Re-query OSRM only when the technician has moved a meaningful distance,
  /// so a 12s poll doesn't hammer the routing service.
  Future<void> _maybeRefreshRoute(Booking b) async {
    if (!b.hasTechnicianFix || !b.hasDestination) return;
    final from = LatLng(b.technicianLat!, b.technicianLng!);
    if (_routedFrom != null &&
        const Distance().as(LengthUnit.Meter, _routedFrom!, from) < 80) {
      return;
    }
    final r = await OsrmApi.instance
        .route(origin: from, destination: LatLng(b.lat!, b.lng!));
    if (!mounted || r == null) return;
    setState(() {
      _osrm = r;
      _routedFrom = from;
    });
    try {
      _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(r.routes.first.points),
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      ));
    } catch (_) {/* map not laid out yet */}
  }

  Future<void> _launchCall(String phone, int? technicianId) async {
    final uri = Uri.parse('tel:$phone');
    final launched = await launchUrl(uri);
    if (!launched) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('couldNotCall'))),
        );
      }
      return;
    }
    if (technicianId == null) return;
    try {
      final call = await CallsApi.instance.start(technicianId);
      _activeCallId = call.callId; // ended in didChangeAppLifecycleState
    } catch (_) {
      // best-effort logging; the call itself already went through
    }
  }

  Future<void> _confirmCancel(Booking b) async {
    final fee = CancellationFee.estimate(b);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t('cancelBookingQ')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t(fee.noteKey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${AppStrings.t('estimatedFee')}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(fee.amount,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.t('keepBooking'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(AppStrings.t('cancelBooking'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      final updated = await BookingsApi.instance.cancel(b.id);
      if (mounted) setState(() => _booking = updated);
      unawaited(BookingsStore.instance.refresh());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('cancelFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final b = _booking;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(b == null ? '' : categoryLabel(b.category)),
      ),
      body: b == null
          ? Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : Text(_loadError!, style: TextStyle(color: p.textSecondary)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (b.status == 'CANCELLED') _cancelledBanner(p),
                  if (b.hasDestination) _mapCard(p, b) else _noMapCard(p),
                  const SizedBox(height: 16),
                  if (b.status != 'CANCELLED') _statusTimeline(p, b),
                  const SizedBox(height: 16),
                  _infoCard(p, b),
                  if (b.technicianName != null) ...[
                    const SizedBox(height: 12),
                    _technicianCard(p, b),
                  ],
                  if (_quotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _quotesCard(p, b),
                  ],
                  if (b.status == 'COMPLETED' && b.technicianName != null) ...[
                    const SizedBox(height: 12),
                    _reviewCard(p, b),
                  ],
                  const SizedBox(height: 12),
                  _detailsCard(p, b),
                  if (b.isCancellable) ...[
                    const SizedBox(height: 12),
                    _feeCard(p, b),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _cancelledBanner(AppPalette p) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(AppStrings.t('bookingCancelledInfo'),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _mapCard(AppPalette p, Booking b) {
    final dest = LatLng(b.lat!, b.lng!);
    final tech = b.hasTechnicianFix
        ? LatLng(b.technicianLat!, b.technicianLng!)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: tech ?? dest,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.camfix_app',
            ),
            if (_osrm != null)
              PolylineLayer(polylines: [
                Polyline(
                    points: _osrm!.routes.first.points,
                    strokeWidth: 5,
                    color: AppColors.primaryBlue),
              ]),
            MarkerLayer(markers: [
              Marker(
                point: dest,
                width: 36,
                height: 36,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on,
                    color: Color(0xFFEA4335), size: 36),
              ),
              if (tech != null)
                Marker(
                  point: tech,
                  width: 34,
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlue, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.build,
                        color: AppColors.primaryBlue, size: 16),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _noMapCard(AppPalette p) => Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(AppStrings.t('noLocationSet'),
            style: TextStyle(color: p.textSecondary)),
      );

  Widget _statusTimeline(AppPalette p, Booking b) {
    final idx = _steps.indexOf(b.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _stepRow(p,
                label: AppStrings.t(_stepKeys[_steps[i]]!),
                done: idx >= 0 && i < idx,
                current: i == idx,
                isLast: i == _steps.length - 1),
        ],
      ),
    );
  }

  Widget _stepRow(AppPalette p,
      {required String label,
      required bool done,
      required bool current,
      required bool isLast}) {
    final color = done || current ? AppColors.primaryBlue : p.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.primaryBlue
                      : (current
                          ? AppColors.white
                          : p.surfaceAlt),
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: AppColors.white)
                    : null,
              ),
              if (!isLast)
                Container(width: 2, height: 20, color: p.border),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label,
                style: TextStyle(
                    color: current ? p.textPrimary : color,
                    fontWeight:
                        current ? FontWeight.w700 : FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(AppPalette p, Booking b) {
    String text;
    switch (b.status) {
      case 'REQUESTED':
        text = AppStrings.t('waitingForTechnician');
      case 'ASSIGNED':
        text = AppStrings.t('technicianAcceptedInfo');
      case 'ON_THE_WAY':
        final r = _osrm?.routes.first;
        text = r == null
            ? AppStrings.t('technicianAcceptedInfo')
            : '${AppSettings.instance.convertKm(r.km).toStringAsFixed(1)} '
                '${AppStrings.t(AppSettings.instance.distanceUnitKey)} · '
                '~${r.minutes} ${AppStrings.t('minShort')} ${AppStrings.t('awayFromYou')}';
      case 'ARRIVED':
        text = AppStrings.t('technicianArrivedInfo');
      case 'QUOTE_PENDING':
        text = AppStrings.t('quotePendingBanner');
      case 'IN_PROGRESS':
        text = AppStrings.t('jobInProgressInfo');
      case 'COMPLETED':
        text = AppStrings.t('jobCompletedInfo');
      default:
        text = AppStrings.t('bookingCancelledInfo');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _technicianCard(AppPalette p, Booking b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.person, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.technicianName!,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.textPrimary)),
                  Text(AppStrings.t('technicianLabel'),
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                ],
              ),
            ),
            if (b.technicianId != null)
              IconButton(
                onPressed: _favoriteBusy
                    ? null
                    : () => _toggleFavorite(b.technicianId!),
                tooltip: AppStrings.t('saveTechnicianTooltip'),
                icon: Icon(
                  _isFavoriteTechnician == true
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavoriteTechnician == true
                      ? const Color(0xFFE5484D)
                      : p.textSecondary,
                ),
              ),
            if (b.technicianPhone != null)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _launchCall(b.technicianPhone!, b.technicianId),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.call, color: AppColors.white, size: 18),
                ),
              ),
          ],
        ),
      );

  Widget _detailsCard(AppPalette p, Booking b) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('descriptionLabel'),
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 6),
            Text(b.description, style: TextStyle(color: p.textPrimary)),
            if ((b.address ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.place_outlined, size: 15, color: p.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(b.address!,
                        style: TextStyle(color: p.textSecondary, fontSize: 13))),
              ]),
            ],
            if (b.bookingType == 'SCHEDULED' && b.scheduledAt != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.event_outlined, size: 15, color: p.textSecondary),
                const SizedBox(width: 6),
                Text('${AppStrings.t('scheduledFor')}: ${b.whenLabel}',
                    style: TextStyle(color: p.textSecondary, fontSize: 13)),
              ]),
            ],
          ],
        ),
      );

  Widget _quotesCard(AppPalette p, Booking b) {
    ServiceQuote? pending;
    for (final q in _quotes) {
      if (q.isPending) {
        pending = q;
        break;
      }
    }
    final history = _quotes.where((q) => q.id != pending?.id).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: pending != null ? AppColors.primaryBlue : p.border,
            width: pending != null ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending != null) _pendingQuoteBlock(p, pending),
          if (pending != null && history.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: p.border, height: 1),
            const SizedBox(height: 14),
          ],
          if (history.isNotEmpty) ...[
            Text(AppStrings.t('quoteHistory'),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary)),
            const SizedBox(height: 8),
            for (final q in history) _historyQuoteRow(p, q),
          ] else if (pending == null && _quotes.isNotEmpty)
            for (final q in _quotes) _historyQuoteRow(p, q),
        ],
      ),
    );
  }

  Widget _pendingQuoteBlock(AppPalette p, ServiceQuote q) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    AppStrings.t(q.version > 1 ? 'quoteRevisedTitle' : 'quoteTitle'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _feeRow(p, AppStrings.t('quoteInspectionFee'), q.inspectionFee),
          _feeRow(p, AppStrings.t('quoteLaborCost'), q.laborCost),
          _feeRow(p, AppStrings.t('quotePartsCost'), q.partsCost),
          _feeRow(p, AppStrings.t('quoteTravelFee'), q.travelFee),
          Divider(color: p.border, height: 18),
          _feeRow(p, AppStrings.t('quoteTotal'), q.totalAmount, bold: true),
          if ((q.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(AppStrings.t('quoteReasonLabel'),
                style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            const SizedBox(height: 2),
            Text(q.reason!, style: TextStyle(fontSize: 13, color: p.textPrimary)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _decidingQuote ? null : () => _decideQuote(q, accept: false),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(44)),
                  child: Text(AppStrings.t('quoteReject')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _decidingQuote ? null : () => _decideQuote(q, accept: true),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size.fromHeight(44)),
                  child: Text(AppStrings.t('quoteAccept')),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _feeRow(AppPalette p, String label, double amount, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: bold ? 14.5 : 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      color: bold ? p.textPrimary : p.textSecondary)),
            ),
            Text('\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: bold ? 15.5 : 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: bold ? AppColors.primaryBlue : p.textPrimary)),
          ],
        ),
      );

  Widget _historyQuoteRow(AppPalette p, ServiceQuote q) {
    final statusKey = switch (q.status) {
      'ACCEPTED' => 'quoteStatusAccepted',
      'REJECTED' => 'quoteStatusRejected',
      'REVISED' => 'quoteStatusRevised',
      _ => 'quoteStatusPending',
    };
    final color = switch (q.status) {
      'ACCEPTED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => p.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text('v${q.version} · \$${q.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: p.textPrimary)),
          ),
          Text(AppStrings.t(statusKey),
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _reviewCard(AppPalette p, Booking b) {
    final r = _review;
    if (r != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.t('yourReviewLabel'),
                style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 8),
            _starPicker(r.rating, readOnly: true),
            if ((r.comment ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment!, style: TextStyle(color: p.textSecondary, fontSize: 13)),
            ],
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.t('rateTechnicianTitle'),
              style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
          const SizedBox(height: 4),
          Text(AppStrings.t('rateTechnicianPrompt'),
              style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 10),
          _starPicker(_pendingStars, readOnly: false),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewComment,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: AppStrings.t('reviewCommentHint'),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submittingReview ? null : _submitReview,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(46)),
              child: Text(_submittingReview
                  ? '${AppStrings.t('submitReview')}…'
                  : AppStrings.t('submitReview')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starPicker(int value, {required bool readOnly}) {
    const amber = Color(0xFFFFB300);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        final icon = Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: readOnly ? 20 : 30,
            color: amber);
        if (readOnly) return icon;
        return InkWell(
          onTap: () => setState(() => _pendingStars = i + 1),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2), child: icon),
        );
      }),
    );
  }

  Widget _feeCard(AppPalette p, Booking b) {
    final fee = CancellationFee.estimate(b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.t('estimatedFee'),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: p.textPrimary)),
              ),
              Text(fee.amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppStrings.t(fee.noteKey),
              style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelling ? null : () => _confirmCancel(b),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(44)),
              child: Text(_cancelling
                  ? '${AppStrings.t('cancelBooking')}…'
                  : AppStrings.t('cancelBooking')),
            ),
          ),
        ],
      ),
    );
  }
}
