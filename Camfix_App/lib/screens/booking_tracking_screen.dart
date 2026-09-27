import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/chat.dart';
import '../models/payment.dart';
import '../models/review.dart';
import '../models/service_quote.dart';
import '../models/service_provider.dart';
import '../services/bookings_api.dart';
import '../services/calls_api.dart';
import '../services/favorites_api.dart';
import '../services/bookings_store.dart';
import '../services/cancellation_fee.dart';
import '../services/osrm_api.dart';
import '../services/api_client.dart';
import '../services/technicians_api.dart';
import '../theme/app_theme.dart';
import 'payment_summary_screen.dart';
import 'services_screen.dart' show categoryLabel;

/// Shows a booking's live status once a technician is involved: a map with
/// the technician's last reported GPS fix + the job address, a status
/// timeline, and (while still cancellable) an estimated cancellation fee.
/// Polls `GET /api/bookings/{id}` every few seconds for real updates, and
/// every [_livePollInterval] while a technician is assigned so their marker
/// glides along with them in near real time. Renders Google Maps (tiles +
/// live traffic) when `GOOGLE_MAPS_API_KEY` is defined, OpenStreetMap otherwise.
class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({super.key});

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const String _mapsKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  bool get _useGoogle => _mapsKey.isNotEmpty;
  static const _livePollInterval = Duration(seconds: 4);

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

  /// The assigned technician's public profile (real rating, jobs done).
  ServiceProvider? _tech;

  /// The recorded payment, once the customer has paid.
  Payment? _payment;
  final _map = MapController();
  gm.GoogleMapController? _gmap;
  Timer? _livePoll;

  /// Technician marker glides from [_techFrom] to [_techTo] over [_glide]
  /// instead of jumping between GPS fixes.
  late final AnimationController _glide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  LatLng? _techFrom;
  LatLng? _techTo;

  LatLng? get _techShown {
    final to = _techTo, from = _techFrom;
    if (to == null || from == null) return to;
    final t = Curves.easeInOut.transform(_glide.value);
    return LatLng(from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t);
  }

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
    _livePoll = Timer.periodic(_livePollInterval, (_) => _refreshLive());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _livePoll?.cancel();
    _glide.dispose();
    _gmap?.dispose();
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
      _moveTech(b);
      if (!b.isOpen) {
        // terminal state - stop polling
        _poll?.cancel();
        _livePoll?.cancel();
      }
      unawaited(_maybeRefreshRoute(b));
      unawaited(_loadQuotes());
      if (b.status == 'COMPLETED') unawaited(_loadReview());
      if (b.technicianId != null && _isFavoriteTechnician == null) {
        unawaited(_loadFavoriteStatus(b.technicianId!));
      }
      if (b.technicianId != null && _tech == null) {
        TechniciansApi.instance.get(b.technicianId!).then((t) {
          if (mounted) setState(() => _tech = t);
        }).catchError((_) {});
      }
      if (b.status == 'IN_PROGRESS' || b.status == 'COMPLETED') {
        BookingsApi.instance.payment(b.id).then((pay) {
          if (mounted) setState(() => _payment = pay);
        }).catchError((_) {});
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  /// Light, fast poll: just the booking, for the technician's latest GPS fix.
  /// A status change hands off to the full [_load].
  Future<void> _refreshLive() async {
    final prev = _booking;
    if (prev == null || !prev.isOpen || prev.technicianId == null) return;
    try {
      final b = await BookingsApi.instance.getOne(_id!);
      if (!mounted) return;
      if (b.status != prev.status) {
        unawaited(_load());
        return;
      }
      setState(() => _booking = b);
      _moveTech(b);
      unawaited(_maybeRefreshRoute(b));
    } catch (_) {
      // transient; the next tick retries
    }
  }

  void _moveTech(Booking b) {
    if (!b.hasTechnicianFix || b.isSelfDrop) return;
    final next = LatLng(b.technicianLat!, b.technicianLng!);
    if (next == _techTo) return;
    _techFrom = _techShown ?? next;
    _techTo = next;
    _glide.forward(from: 0);
  }

  /// Frame [points] on whichever map is showing.
  void _fitPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    if (_useGoogle) {
      var minLat = points.first.latitude, maxLat = minLat;
      var minLng = points.first.longitude, maxLng = minLng;
      for (final q in points) {
        if (q.latitude < minLat) minLat = q.latitude;
        if (q.latitude > maxLat) maxLat = q.latitude;
        if (q.longitude < minLng) minLng = q.longitude;
        if (q.longitude > maxLng) maxLng = q.longitude;
      }
      _gmap
          ?.animateCamera(gm.CameraUpdate.newLatLngBounds(
              gm.LatLngBounds(
                  southwest: gm.LatLng(minLat, minLng),
                  northeast: gm.LatLng(maxLat, maxLng)),
              32))
          .catchError((_) {/* map not laid out yet */});
      return;
    }
    try {
      _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(32),
      ));
    } catch (_) {/* map not laid out yet */}
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('reviewRequired'))));
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
        content: Text(AppStrings.t(accept
            ? 'quoteAcceptConfirmMessage'
            : 'quoteRejectConfirmMessage')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: accept
                  ? null
                  : FilledButton.styleFrom(backgroundColor: Colors.red),
              child:
                  Text(AppStrings.t(accept ? 'quoteAccept' : 'quoteReject'))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _decidingQuote = true);
    try {
      final updated = accept
          ? await BookingsApi.instance.acceptQuote(_id!, q.id,
              approvedItemIds: q.items.isEmpty ? null : _approvedIds(q))
          : await BookingsApi.instance.rejectQuote(_id!, q.id);
      if (mounted) setState(() => _booking = updated);
      unawaited(BookingsStore.instance.refresh());
      if (mounted && accept) {
        // The server recomputed the total from only the approved items -
        // pay exactly that, not the "everything approved" preview.
        final fresh = await BookingsApi.instance.quotes(_id!);
        if (mounted) setState(() => _quotes = fresh);
        final accepted = fresh.firstWhere((x) => x.id == q.id, orElse: () => q);
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              PaymentSummaryScreen(booking: updated, quote: accepted),
        ));
        unawaited(_load());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t('quoteRejected'))));
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
    // Self Drop: the destination is the technician's own shop - no route.
    if (b.isSelfDrop || !b.hasTechnicianFix || !b.hasDestination) return;
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
    _fitPoints(r.routes.first.points);
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
        backgroundColor: p.background,
        elevation: 0,
        title: Text(AppStrings.t('trackingTechnician'),
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: p.textPrimary)),
        iconTheme: IconThemeData(color: p.textPrimary),
        actions: [
          IconButton(
            tooltip: AppStrings.t('helpCenter'),
            onPressed: () => Navigator.of(context).pushNamed('/help-support'),
            icon: const Icon(Icons.help_outline_rounded,
                color: Color(0xFF1E9E52)),
          ),
        ],
      ),
      body: b == null
          ? Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : Text(_loadError!, style: TextStyle(color: p.textSecondary)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (b.status == 'CANCELLED') _cancelledBanner(p),
                  _statusCard(p, b),
                  ..._stageSection(p, b),
                  const SizedBox(height: 14),
                  _progressCard(p, b),
                  if (b.isCancellable) ...[
                    const SizedBox(height: 12),
                    _feeCard(p, b),
                  ],
                ],
              ),
            ),
    );
  }

  // --- Stage model ------------------------------------------------------------

  /// 1..7 = the step currently happening; 8 = everything done (reviewed).
  int _currentStep(Booking b) => switch (b.status) {
        'REQUESTED' => 1,
        // Accepted: step 1 is done, travelling is up next.
        'ASSIGNED' || 'ON_THE_WAY' => 2,
        'ARRIVED' => 3,
        'QUOTE_PENDING' => 4,
        'IN_PROGRESS' => 5,
        'COMPLETED' => _review == null ? 7 : 8,
        _ => 1,
      };

  static const _stepTitleKeys = [
    'stageWaiting',
    'stageTraveling',
    'stageArrived',
    'stageDiagnose',
    'stageRepair',
    'stageComplete',
    'stageReview',
  ];

  String _stepTitle(int i, Booking b) {
    if (b.isSelfDrop && i == 1) return AppStrings.t('stepReadyForDropOff');
    if (b.isSelfDrop && i == 2) return AppStrings.t('stepItemReceived');
    return AppStrings.t(_stepTitleKeys[i]);
  }

  String _stepDesc(int i, Booking b) {
    final tech = b.technicianName ?? AppStrings.t('technicianLabel');
    return switch (i) {
      0 => '${AppStrings.t('stageWaitingDesc')} ${categoryLabel(b.category)}',
      1 => b.isSelfDrop
          ? AppStrings.t('selfDropBringInfo')
          : '$tech ${AppStrings.t('stageTravelingDesc')}',
      2 => b.isSelfDrop
          ? AppStrings.t('selfDropReceivedInfo')
          : AppStrings.t('stageArrivedDesc'),
      3 => AppStrings.t('stageDiagnoseDesc'),
      4 => AppStrings.t('stageRepairDesc'),
      5 => AppStrings.t('stageCompleteDesc'),
      _ => AppStrings.t('stageReviewDesc'),
    };
  }

  /// Only timestamps the backend really records.
  DateTime? _stepTime(int i, Booking b) => switch (i) {
        0 => b.createdAt,
        1 => b.assignedAt,
        5 => b.completedAt,
        6 => _review?.createdAt,
        _ => null,
      };

  static String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  // --- Status card ------------------------------------------------------------

  Widget _statusCard(AppPalette p, Booking b) {
    final step = _currentStep(b);
    final done = (step - 1).clamp(0, 7);
    final cancelled = b.status == 'CANCELLED';
    final (label, color) = cancelled
        ? (AppStrings.t('statusCancelled'), const Color(0xFFE5484D))
        : b.status == 'REQUESTED'
            ? (AppStrings.t('notYetAccepted'), const Color(0xFFE5484D))
            : b.status == 'ASSIGNED'
                ? (AppStrings.t('bookingAccepted'), AppColors.primaryBlue)
                : b.status == 'COMPLETED'
                    ? (AppStrings.t('stepCompleted'), const Color(0xFF1E9E52))
                    : (AppStrings.t('liveWord'), AppColors.primaryBlue);
    final title = cancelled
        ? AppStrings.t('statusCancelled')
        : b.status == 'ASSIGNED'
            ? AppStrings.t('bookingAccepted')
            : _stepTitle((step - 1).clamp(0, 6), b);
    final ringColor = b.status == 'COMPLETED'
        ? const Color(0xFF1E9E52)
        : AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: done / 7,
                strokeWidth: 5,
                backgroundColor: p.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(AppStrings.t('statusCaps'),
                  style: TextStyle(
                      fontSize: 7.5,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary)),
              Text('${step.clamp(1, 7)} of 7',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: p.textPrimary)),
              Text('${(done / 7 * 100).round()}%',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ringColor)),
            ]),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 3.5, backgroundColor: color),
              const SizedBox(width: 5),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ]),
            const SizedBox(height: 3),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
            const SizedBox(height: 2),
            Text(_statusSubtitle(b),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  String _statusSubtitle(Booking b) {
    final tech = b.technicianName ?? AppStrings.t('technicianLabel');
    return switch (b.status) {
      'REQUESTED' => AppStrings.t('waitingForTechnician'),
      'ASSIGNED' => b.isSelfDrop
          ? '${AppStrings.t('selfDropBringInfo')} ${b.whenLabel}'
          : '$tech ${AppStrings.t('acceptedYourBooking')}',
      'ON_THE_WAY' => b.isSelfDrop
          ? '${AppStrings.t('selfDropBringInfo')} ${b.whenLabel}'
          : '$tech ${AppStrings.t('stageTravelingDesc')}',
      'ARRIVED' => b.isSelfDrop
          ? AppStrings.t('selfDropReceivedInfo')
          : AppStrings.t('technicianArrivedInfo'),
      'QUOTE_PENDING' => AppStrings.t('quotePendingBanner'),
      'IN_PROGRESS' => AppStrings.t('jobInProgressInfo'),
      'COMPLETED' => AppStrings.t('jobCompletedInfo'),
      _ => AppStrings.t('bookingCancelledInfo'),
    };
  }

  // --- Per-stage content --------------------------------------------------------

  List<Widget> _stageSection(AppPalette p, Booking b) {
    final s = b.status;
    final arrivedOrLater = const {
      'ARRIVED',
      'QUOTE_PENDING',
      'IN_PROGRESS',
      'COMPLETED'
    }.contains(s);
    final hasAccepted = _quotes.any((q) => q.isAccepted);
    return [
      if (arrivedOrLater && !b.isSelfDrop) ...[
        const SizedBox(height: 10),
        _arrivedStrip(p),
      ],
      if (s == 'ON_THE_WAY' && !b.isSelfDrop) ...[
        const SizedBox(height: 14),
        _liveHeader(p, b),
      ],
      if ((s == 'ASSIGNED' || s == 'ON_THE_WAY' || s == 'ARRIVED') &&
          b.hasDestination) ...[
        const SizedBox(height: 12),
        _mapCard(p, b),
      ],
      if (b.technicianName != null) ...[
        const SizedBox(height: 12),
        _techCard(p, b),
      ],
      if (_quotes.isNotEmpty && (s == 'ARRIVED' || s == 'QUOTE_PENDING')) ...[
        const SizedBox(height: 12),
        _quoteReviewHeader(p, b),
        const SizedBox(height: 8),
        _quotesCard(p, b),
      ],
      if (s == 'IN_PROGRESS' || s == 'COMPLETED' || s == 'CANCELLED') ...[
        const SizedBox(height: 12),
        _serviceSummary(p, b),
      ],
      if (hasAccepted) ...[
        const SizedBox(height: 12),
        _paymentBreakdown(p, b),
      ],
      if (s == 'COMPLETED' && b.technicianName != null) ...[
        const SizedBox(height: 12),
        _reviewCard(p, b),
      ],
    ];
  }

  Widget _arrivedStrip(AppPalette p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E9E52).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.person_pin_circle_rounded,
              size: 18, color: Color(0xFF1E9E52)),
          const SizedBox(width: 8),
          Text(AppStrings.t('technicianHasArrived'),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E9E52))),
        ]),
      );

  /// LIVE SERVICE TRACKING - real road ETA from OSRM (or distance only).
  Widget _liveHeader(AppPalette p, Booking b) {
    final r = _osrm?.routes.first;
    final eta =
        r == null ? null : DateTime.now().add(Duration(minutes: r.minutes));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bolt_rounded,
                size: 13, color: AppColors.primaryBlue),
            const SizedBox(width: 3),
            Text(AppStrings.t('liveServiceTracking'),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue)),
          ]),
        ),
        if (eta != null) ...[
          const SizedBox(width: 8),
          Text('${AppStrings.t('estWord')} ${_clock(eta)}',
              style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
        ],
      ]),
      const SizedBox(height: 8),
      Text(
          r == null
              ? AppStrings.t('stepOnTheWay')
              : '${AppStrings.t('arrivingIn')} ${r.minutes} ${AppStrings.t('minShort')}',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: p.textPrimary)),
      if ((b.address ?? '').isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.home_rounded,
              size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.address!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              if (r != null)
                Text(
                    '${AppSettings.instance.convertKm(r.km).toStringAsFixed(1)} ${AppStrings.t(AppSettings.instance.distanceUnitKey)} ${AppStrings.t('awayFromYou')}',
                    style: TextStyle(fontSize: 11, color: p.textSecondary)),
            ]),
          ),
          FilledButton.tonal(
            onPressed: _fitRoute,
            style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(AppStrings.t('trackWord')),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ]),
          ),
        ]),
      ],
    ]);
  }

  /// "Tracking" recentres the live map on the technician's route.
  void _fitRoute() {
    final r = _osrm?.routes.first;
    if (r == null) return;
    _fitPoints(r.points);
  }

  /// Technician: real photo, rating, jobs done; chat + call + favorite.
  Widget _techCard(AppPalette p, Booking b) {
    final t = _tech;
    final photo = b.technicianId == null
        ? null
        : '${ApiClient.instance.baseUrl}/api/technician/${b.technicianId}/photo';
    final meta = <String>[
      if (t != null) categoryLabel(t.category),
      if (t != null && t.completedJobCount > 0)
        '${t.completedJobCount} ${AppStrings.t(t.completedJobCount == 1 ? 'jobDoneWord' : 'jobsDoneWord')}',
    ].join(' • ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: p.surfaceAlt,
          foregroundImage: photo == null ? null : NetworkImage(photo),
          onForegroundImageError: photo == null ? null : (_, __) {},
          child: const Icon(Icons.person, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(b.technicianName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded,
                  size: 15, color: AppColors.primaryBlue),
            ]),
            if (meta.isNotEmpty)
              Text(meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            if (t != null && t.ratingCount > 0)
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 2),
                Text('${t.rating.toStringAsFixed(1)} (${t.ratingCount})',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary)),
              ]),
          ]),
        ),
        if (b.technicianId != null)
          IconButton(
            tooltip: AppStrings.t('saveTechnicianTooltip'),
            onPressed:
                _favoriteBusy ? null : () => _toggleFavorite(b.technicianId!),
            icon: Icon(
              _isFavoriteTechnician == true
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 20,
              color: _isFavoriteTechnician == true
                  ? const Color(0xFFE5484D)
                  : p.textSecondary,
            ),
          ),
        if (b.technicianId != null)
          _roundBtn(
            p,
            Icons.chat_bubble_rounded,
            filled: false,
            onTap: () => Navigator.of(context).pushNamed(
              '/chat-thread',
              arguments: ChatThreadArgs(
                jobId: b.id,
                name: b.technicianName ?? AppStrings.t('technicianLabel'),
                category: b.category,
                phone: b.technicianPhone,
                technicianId: b.technicianId,
              ),
            ),
          ),
        if (b.technicianPhone != null) ...[
          const SizedBox(width: 8),
          _roundBtn(p, Icons.call_rounded,
              filled: true,
              onTap: () => _launchCall(b.technicianPhone!, b.technicianId)),
        ],
      ]),
    );
  }

  Widget _roundBtn(AppPalette p, IconData icon,
          {required bool filled, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: filled ? AppColors.textDark : p.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18, color: filled ? Colors.white : AppColors.primaryBlue),
        ),
      );

  Widget _quoteReviewHeader(AppPalette p, Booking b) {
    final pending = _quotes.any((q) => q.isPending);
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppStrings.t('quoteReviewTitle'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary)),
          Text(AppStrings.t('quoteReviewSub'),
              style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
        ]),
      ),
      if (pending)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1DC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(AppStrings.t('actionRequired'),
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB26A00))),
        ),
    ]);
  }

  /// Service, booking type, date/time and address - like the receipt.
  Widget _serviceSummary(AppPalette p, Booking b) {
    final cut = b.description.indexOf(' - booked via app');
    final title =
        cut > 0 ? b.description.substring(0, cut) : categoryLabel(b.category);
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            TextStyle(fontSize: 10.5, color: p.textSecondary)),
                    Text(value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary)),
                  ]),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.home_repair_service_rounded,
                color: AppColors.primaryBlue, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${categoryLabel(b.category)} • ${AppStrings.t(b.isSelfDrop ? 'selfDrop' : (b.bookingType == 'SCHEDULED' ? 'appointment' : 'bookNowChip'))}',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E9E52))),
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary)),
                  ]),
            ),
          ]),
        ),
        row(Icons.calendar_month_rounded, AppStrings.t('dateWindow'),
            b.whenLabel.replaceAll('   ', '  ')),
        if ((b.address ?? '').isNotEmpty)
          row(
              b.isSelfDrop
                  ? Icons.storefront_rounded
                  : Icons.location_on_rounded,
              AppStrings.t(b.isSelfDrop ? 'dropOffLocation' : 'serviceAddress'),
              b.address!),
      ]),
    );
  }

  /// PAYMENT BREAKDOWN from the accepted quote; "Paid" only when a payment
  /// was actually recorded.
  Widget _paymentBreakdown(AppPalette p, Booking b) {
    final q = _quotes.lastWhere((q) => q.isAccepted);
    final est = PaymentBreakdown.fromQuote(q);
    final pay = _payment;
    Widget line(String label, double v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                      color: strong ? p.textPrimary : p.textSecondary)),
            ),
            Text('\$${v.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(AppStrings.t('paymentBreakdown'),
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pay != null
                  ? const Color(0xFFE8F8F1)
                  : const Color(0xFFFFF3DD),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
                pay != null
                    ? '✓ ${AppStrings.t('paidBadge')}'
                    : AppStrings.t('unpaidBadge'),
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: pay != null
                        ? const Color(0xFF1E9E52)
                        : const Color(0xFFB26A00))),
          ),
        ]),
        const SizedBox(height: 8),
        // Only the line items the customer approved are charged.
        for (final it in q.items.where((i) => i.approved == true))
          line(it.title, it.price),
        if (q.inspectionFee > 0)
          line(AppStrings.t('quoteInspectionFee'), q.inspectionFee),
        if (q.laborCost > 0) line(AppStrings.t('quoteLaborCost'), q.laborCost),
        if (q.partsCost > 0) line(AppStrings.t('quotePartsCost'), q.partsCost),
        if (q.travelFee > 0) line(AppStrings.t('quoteTravelFee'), q.travelFee),
        line(AppStrings.t('subtotal'), pay?.baseAmount ?? q.totalAmount,
            strong: true),
        line(AppStrings.t('platformProcessing'),
            pay?.platformFee ?? est.platformFee),
        line(AppStrings.t('taxes85'), pay?.taxAmount ?? est.tax),
        Divider(height: 18, color: p.border),
        Row(children: [
          Expanded(
            child: Text(AppStrings.t('totalAmount'),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
          ),
          Text('\$${(pay?.totalAmount ?? est.total).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue)),
        ]),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context)
                .pushNamed('/booking-receipt', arguments: b.id),
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: Text(AppStrings.t('viewReceipt')),
          ),
        ),
      ]),
    );
  }

  // --- Service Progress timeline ---------------------------------------------

  Widget _progressCard(AppPalette p, Booking b) {
    final current = _currentStep(b);
    final cancelled = b.status == 'CANCELLED';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.t('serviceProgress'),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary)),
        Text(AppStrings.t('serviceProgressSub'),
            style: TextStyle(fontSize: 11, color: p.textSecondary)),
        const SizedBox(height: 12),
        for (var i = 0; i < 7; i++)
          _progressRow(p, b,
              index: i,
              done: !cancelled && i + 1 < current,
              active: !cancelled && i + 1 == current,
              last: i == 6),
      ]),
    );
  }

  Widget _progressRow(AppPalette p, Booking b,
      {required int index,
      required bool done,
      required bool active,
      required bool last}) {
    const green = Color(0xFF1E9E52);
    final time = _stepTime(index, b);
    final state = done
        ? AppStrings.t('doneState')
        : active
            ? AppStrings.t(
                b.status == 'ASSIGNED' ? 'upNextState' : 'inProgressState')
            : AppStrings.t('pendingState');
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 28,
          child: Column(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? green
                    : active
                        ? AppColors.primaryBlue
                        : p.surface,
                border: Border.all(
                    color: done
                        ? green
                        : active
                            ? AppColors.primaryBlue
                            : p.border,
                    width: 1.5),
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white)
                  : Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : p.textSecondary)),
            ),
            if (!last)
              Expanded(
                child: Container(width: 2, color: done ? green : p.border),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(_stepTitle(index, b),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color:
                              active ? AppColors.primaryBlue : p.textPrimary)),
                ),
                if (time != null)
                  Text(_clock(time),
                      style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
              ]),
              const SizedBox(height: 2),
              Text(_stepDesc(index, b),
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
              const SizedBox(height: 3),
              Text(state,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: done
                          ? green
                          : active
                              ? AppColors.primaryBlue
                              : p.textSecondary)),
            ]),
          ),
        ),
      ]),
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
    final showTech = b.hasTechnicianFix && !b.isSelfDrop;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glide,
              builder: (context, _) {
                final tech = showTech ? _techShown : null;
                return _useGoogle
                    ? _googleMap(b, dest, tech)
                    : _osmMap(b, dest, tech);
              },
            ),
          ),
          if (showTech && b.technicianLocationAt != null)
            Positioned(top: 10, left: 10, child: _freshnessChip(p, b)),
        ]),
      ),
    );
  }

  Widget _googleMap(Booking b, LatLng dest, LatLng? tech) {
    gm.LatLng g(LatLng q) => gm.LatLng(q.latitude, q.longitude);
    return gm.GoogleMap(
      initialCameraPosition:
          gm.CameraPosition(target: g(tech ?? dest), zoom: 14),
      onMapCreated: (c) {
        _gmap = c;
        final r = _osrm?.routes.first;
        if (r != null) _fitPoints(r.points);
      },
      trafficEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      polylines: {
        if (_osrm != null)
          gm.Polyline(
            polylineId: const gm.PolylineId('route'),
            points: _osrm!.routes.first.points.map(g).toList(),
            width: 5,
            color: AppColors.primaryBlue,
          ),
      },
      markers: {
        gm.Marker(
          markerId: const gm.MarkerId('dest'),
          position: g(dest),
          infoWindow: gm.InfoWindow(title: b.address),
        ),
        if (tech != null)
          gm.Marker(
            markerId: const gm.MarkerId('tech'),
            position: g(tech),
            zIndexInt: 1,
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(
                gm.BitmapDescriptor.hueAzure),
            infoWindow: gm.InfoWindow(title: b.technicianName),
          ),
      },
    );
  }

  Widget _osmMap(Booking b, LatLng dest, LatLng? tech) => FlutterMap(
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
              child: Icon(
                  b.isSelfDrop ? Icons.storefront_rounded : Icons.location_on,
                  color: const Color(0xFFEA4335),
                  size: 36),
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
      );

  /// "● Live · 8s ago" - green while the last GPS fix is fresh, grey once
  /// the technician's phone has gone quiet for over a minute.
  Widget _freshnessChip(AppPalette p, Booking b) {
    final age = DateTime.now().difference(b.technicianLocationAt!);
    final fresh = age.inSeconds < 60;
    final String ago;
    if (age.inSeconds < 10) {
      ago = AppStrings.t('justNow');
    } else if (age.inMinutes < 1) {
      ago = '${age.inSeconds}${AppStrings.t('secAgo')}';
    } else if (age.inHours < 1) {
      ago = '${age.inMinutes} ${AppStrings.t('minAgo')}';
    } else {
      ago = '${age.inHours}${AppStrings.t('hrAgo')}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: fresh ? const Color(0xFF34A853) : p.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text('${AppStrings.t('live')} · $ago',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.textPrimary)),
      ]),
    );
  }

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

  /// Per-quote ticked item ids (customer's choice before accepting).
  final Map<int, Set<int>> _itemChoice = {};

  /// Default: the technician's core items ticked, "recommended" extras not.
  Set<int> _choiceFor(ServiceQuote q) => _itemChoice.putIfAbsent(
      q.id,
      () => {
            for (final i in q.items)
              if (!i.recommended) i.id
          });

  List<int> _approvedIds(ServiceQuote q) => _choiceFor(q).toList();

  /// Technician Quotation Review: inspection notes, tickable line items,
  /// always-included fees and a live breakdown of what will be charged.
  Widget _pendingQuoteBlock(AppPalette p, ServiceQuote q) {
    final chosen = _choiceFor(q);
    final itemsSum = q.items
        .where((i) => chosen.contains(i.id))
        .fold<double>(0, (s, i) => s + i.price);
    final subtotal = q.feesTotal + itemsSum;
    final platformFee = subtotal * 0.018 < 0.99 ? 0.99 : subtotal * 0.018;
    final tax = (subtotal + platformFee) * 0.085;
    final total = subtotal + platformFee + tax;
    String money(double v) => '\$${v.toStringAsFixed(2)}';
    const green = Color(0xFF1E9E52);

    Widget itemCard(QuoteItem it) {
      final on = chosen.contains(it.id);
      return GestureDetector(
        onTap: () =>
            setState(() => on ? chosen.remove(it.id) : chosen.add(it.id)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: on ? AppColors.primaryBlue : p.border,
                width: on ? 1.5 : 1),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: on ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: on ? AppColors.primaryBlue : p.textSecondary,
                    width: 1.5),
              ),
              child: on
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (it.recommended ? p.textSecondary : green)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                          AppStrings.t(it.recommended
                              ? 'techRecommended'
                              : 'quotedWork'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: it.recommended ? p.textSecondary : green)),
                    ),
                    if ((it.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(it.note!,
                          style: TextStyle(
                              fontSize: 11.5, color: p.textSecondary)),
                    ],
                  ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(it.price),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: p.textPrimary)),
              Text(AppStrings.t(on ? 'itemIncluded' : 'itemSkipped'),
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: on ? green : p.textSecondary)),
            ]),
          ]),
        ),
      );
    }

    Widget line(String label, double v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                      color: strong ? p.textPrimary : p.textSecondary)),
            ),
            Text(money(v),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (q.version > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(AppStrings.t('quoteRevisedTitle'),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
        ),
      if ((q.reason ?? '').isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD93A56).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.manage_search_rounded,
                  size: 17, color: Color(0xFFD93A56)),
              const SizedBox(width: 6),
              Text(AppStrings.t('inspectionSummary'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
            ]),
            const SizedBox(height: 4),
            Text(q.reason!,
                style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      for (final it in q.items) itemCard(it),
      if (q.feesTotal > 0) ...[
        Text(AppStrings.t('alwaysIncluded'),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: p.textSecondary)),
        if (q.inspectionFee > 0)
          line(AppStrings.t('quoteInspectionFee'), q.inspectionFee),
        if (q.laborCost > 0) line(AppStrings.t('quoteLaborCost'), q.laborCost),
        if (q.partsCost > 0) line(AppStrings.t('quotePartsCost'), q.partsCost),
        if (q.travelFee > 0) line(AppStrings.t('quoteTravelFee'), q.travelFee),
        const SizedBox(height: 10),
      ],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppStrings.t('paymentBreakdown'),
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary)),
          const SizedBox(height: 6),
          for (final it in q.items.where((i) => chosen.contains(i.id)))
            line(it.title, it.price, strong: true),
          if (q.feesTotal > 0) line(AppStrings.t('feesWord'), q.feesTotal),
          line(AppStrings.t('platformProcessing'), platformFee),
          line(AppStrings.t('taxes85'), tax),
          Divider(height: 16, color: p.border),
          Row(children: [
            Expanded(
              child: Text(AppStrings.t('totalAmount'),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
            ),
            Text(money(total),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed:
              _decidingQuote ? null : () => _decideQuote(q, accept: true),
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: Text(AppStrings.t('confirmWord'),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ),
      const SizedBox(height: 4),
      Center(
        child: TextButton(
          onPressed:
              _decidingQuote ? null : () => _decideQuote(q, accept: false),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(AppStrings.t('declineWholeQuote')),
        ),
      ),
      if (q.items.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD93A56).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: Color(0xFFD93A56)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(AppStrings.t('customizeQuoteNote'),
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            ),
          ]),
        ),
    ]);
  }

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
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: p.textPrimary)),
            const SizedBox(height: 8),
            _starPicker(r.rating, readOnly: true),
            if ((r.comment ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.comment!,
                  style: TextStyle(color: p.textSecondary, fontSize: 13)),
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
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
