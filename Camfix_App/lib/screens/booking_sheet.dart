import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../models/technician_service_listing.dart';
import '../services/api_client.dart';
import '../services/bookings_store.dart';
import '../services/device_location.dart';
import '../services/notifications_store.dart';
import '../services/service_prices_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import 'services_screen.dart' show categoryLabel;

/// "Book Now" flow for a provider: pick a service, a day and time, add a note,
/// confirm. Sends the booking to the backend (`POST /api/bookings`, which
/// creates a job + notifications) and ends on a success dialog. Pass
/// [listing] when the customer tapped "Book Now" on one of the technician's
/// own real service listings (Achievements tab) - the generic service picker
/// is skipped and that listing's real price is booked instead.
Future<void> showBookingSheet(BuildContext context, ServiceProvider p,
    {TechnicianServiceListing? listing}) {
  // Full-screen booking page (Appointment | Self Drop), per the mockup.
  return Navigator.of(context).push<void>(MaterialPageRoute(
    builder: (_) => _BookingSheet(provider: p, listing: listing),
  ));
}

/// When a Self Drop customer plans to arrive at the technician's shop.
enum _Arrival { now, inOneHour, afternoon, custom }

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.provider, this.listing});
  final ServiceProvider provider;
  final TechnicianServiceListing? listing;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  // Stable ids kept in the booking; shown through [_serviceLabel] so the
  // chips and confirmation follow the app language.
  static const _services = ['Repair', 'Clean', 'Installation', 'Inspection'];

  static String _serviceLabel(String id) => switch (id) {
        'Repair' => AppStrings.t('svcRepair'),
        'Clean' => AppStrings.t('svcClean'),
        'Installation' => AppStrings.t('svcInstallation'),
        'Inspection' => AppStrings.t('svcInspection'),
        _ => id,
      };
  static const _timeSlots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];
  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final _note = TextEditingController();
  String _service = _services.first;
  bool _scheduled = true; // false = book now (Immediate), true = pick a time
  bool _selfDrop = false;
  DateTime? _date;
  TimeOfDay? _time;
  late DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  String? _address; // where the technician should come — "lat, lng" or typed
  LatLng? _pickedLatLng;
  bool _submitting = false;
  double? _startingPrice;
  _Arrival _arrival = _Arrival.now;

  /// Admin-set catalog row for this category - carries the real Self Drop
  /// bench fee and home-visit travel fee (either may be null = not set).
  ServicePriceInfo? _pricing;

  /// Customer's GPS fix, for the real distance to the shop (null = unknown).
  LatLng? _myPos;

  /// Self Drop needs a real technician: the drop-off point is their shop, and
  /// the backend rejects a Self Drop without one.
  bool get _canSelfDrop => widget.provider.technicianId != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill from the saved default address (Profile → Preference) so the
    // user doesn't have to pick a location for every booking.
    final settings = AppSettings.instance;
    if (settings.hasDefaultAddress) {
      _address = settings.defaultAddress;
      _pickedLatLng =
          LatLng(settings.defaultAddressLat!, settings.defaultAddressLng!);
    }
    if (widget.listing != null) {
      _startingPrice = widget.listing!.price;
    }
    // "Starting from $X" — a catalog estimate, never the final repair cost
    // (that comes later as a real ServiceQuote once a technician inspects).
    getCurrentLocation().then((fix) {
      if (mounted && fix.ok) {
        setState(() =>
            _myPos = LatLng(fix.position!.latitude, fix.position!.longitude));
      }
    });
    ServicePricesApi.instance.infoFor(widget.provider.category).then((info) {
      if (!mounted) return;
      setState(() {
        _pricing = info;
        _startingPrice ??= info?.startingPrice;
      });
    });
  }

  /// Next 2:00 PM - today if it's still before then, otherwise tomorrow.
  DateTime get _nextAfternoon {
    final now = DateTime.now();
    final today2pm = DateTime(now.year, now.month, now.day, 14);
    return now.isBefore(today2pm)
        ? today2pm
        : today2pm.add(const Duration(days: 1));
  }

  /// The moment this booking is for, from whichever picker is active.
  DateTime? get _when {
    if (_selfDrop && _arrival != _Arrival.custom) {
      return switch (_arrival) {
        _Arrival.inOneHour => DateTime.now().add(const Duration(hours: 1)),
        _Arrival.afternoon => _nextAfternoon,
        _ => DateTime.now(),
      };
    }
    if (_date == null || _time == null) return null;
    return DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _ready =>
      !_submitting &&
      (_selfDrop ? _canSelfDrop : _address != null) &&
      _when != null;

  String get _dropOffAddress {
    final address = widget.provider.address.trim();
    if (address.isNotEmpty && address != '—') return address;
    final location = widget.provider.location.trim();
    if (location.isNotEmpty) return location;
    return 'Technician service location';
  }

  String? get _bookingAddress => _selfDrop ? _dropOffAddress : _address;

  LatLng? get _bookingLatLng {
    if (_selfDrop) {
      return widget.provider.hasLocation
          ? LatLng(widget.provider.latitude, widget.provider.longitude)
          : null;
    }
    return _pickedLatLng;
  }

  // Self Drop now travels as a real bookingType, so the note is just the note.
  String? get _bookingNote {
    final typed = _note.text.trim();
    return typed.isEmpty ? null : typed;
  }

  static LatLng? _parseLatLng(String s) {
    final m = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(s);
    return m == null
        ? null
        : LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!));
  }

  Future<void> _pickOnMap() async {
    FocusScope.of(context).unfocus();
    // Reopen on the last-picked point if the address was already set once.
    final start = _address == null ? null : _parseLatLng(_address!);
    final result =
        await Navigator.of(context).pushNamed('/map-picker', arguments: start);
    if (result is LatLng) {
      setState(() {
        _pickedLatLng = result;
        _address = '${result.latitude.toStringAsFixed(6)}, '
            '${result.longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);

    final when = _when ?? DateTime.now();
    final bookingType =
        _selfDrop ? 'SELF_DROP' : (_scheduled ? 'SCHEDULED' : 'IMMEDIATE');

    Map<String, dynamic> response;
    try {
      response = await ApiClient.instance.postJson(
        '/api/bookings',
        {
          'category': widget.provider.category,
          'service': _service,
          'note': _bookingNote,
          'address': _bookingAddress,
          'lat': _bookingLatLng?.latitude,
          'lng': _bookingLatLng?.longitude,
          'scheduledAt':
              (_selfDrop || _scheduled) ? when.toUtc().toIso8601String() : null,
          'bookingType': bookingType,
          'providerName': widget.provider.name,
          if (widget.provider.technicianId != null)
            'technicianId': widget.provider.technicianId,
          if (widget.listing != null) 'technicianServiceId': widget.listing!.id,
        },
        withAuth: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${AppStrings.t('bookingFailed')}: ${e.message}')),
      );
      return;
    }
    if (!mounted) return;

    // Refresh from the backend rather than adding a local guess — the server
    // already has the real booking (id, status) by the time the POST returns.
    unawaited(BookingsStore.instance.refresh());
    unawaited(NotificationsStore.instance.refresh());

    final jobId = (response['id'] as num?)?.toInt();
    final navigator = Navigator.of(context);
    navigator.pop(); // close the sheet
    final track = await showDialog<bool>(
      context: context,
      builder: (_) => _BookingDoneDialog(
        provider: widget.provider.name,
        service: _serviceLabel(_service),
        address: _bookingAddress!,
      ),
    );
    if (track == true && jobId != null) {
      navigator.pushNamed('/booking-tracking', arguments: jobId);
    }
  }

  // --- Real data helpers for the page ---------------------------------------

  /// Real distance from the customer's GPS fix to the technician, or null.
  double? get _distanceKm {
    final me = _myPos;
    final p = widget.provider;
    if (me == null || !p.hasLocation) return null;
    return distanceKmBetween(
        me.latitude, me.longitude, p.latitude, p.longitude);
  }

  String? get _distanceLabel {
    final km = _distanceKm;
    if (km == null) return null;
    final s = AppSettings.instance;
    return '${s.convertKm(km).toStringAsFixed(1)} ${AppStrings.t(s.distanceUnitKey)}';
  }

  static final _hoursRe = RegExp(
      r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])\s*[-–]\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])');

  static int _toMinutes(String h, String m, String ampm) {
    var hour = int.parse(h) % 12;
    if (ampm.toUpperCase() == 'PM') hour += 12;
    return hour * 60 + int.parse(m);
  }

  /// "Open now · until 5:00 PM" / "Closed · opens 6:00 AM" - only when the
  /// technician's own opening hours are a plain daily "h:mm AM - h:mm PM"
  /// range. Hours that name specific days are shown as written instead, so
  /// we never claim "open" on a day they aren't.
  (bool? open, String text) get _hoursBadge {
    final raw = widget.provider.openingHours.trim();
    final m = _hoursRe.firstMatch(raw);
    final namesDays =
        RegExp(r'mon|tue|wed|thu|fri|sat|sun', caseSensitive: false)
            .hasMatch(raw);
    if (m == null || namesDays) return (null, raw);
    final start = _toMinutes(m.group(1)!, m.group(2)!, m.group(3)!);
    final end = _toMinutes(m.group(4)!, m.group(5)!, m.group(6)!);
    final now = DateTime.now();
    final cur = now.hour * 60 + now.minute;
    final open =
        start <= end ? cur >= start && cur < end : cur >= start || cur < end;
    return open
        ? (
            true,
            '${AppStrings.t('openNow')} • ${AppStrings.t('untilWord')} ${m.group(4)}:${m.group(5)} ${m.group(6)!.toUpperCase()}'
          )
        : (
            false,
            '${AppStrings.t('closedNow')} • ${AppStrings.t('opensWord')} ${m.group(1)}:${m.group(2)} ${m.group(3)!.toUpperCase()}'
          );
  }

  double? get _travelFee {
    final t = _pricing?.travelFee;
    return t == null || t <= 0 ? null : t;
  }

  // --- Page -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        iconTheme: IconThemeData(color: p.textPrimary),
        actions: [
          IconButton(
            tooltip: AppStrings.t('favorites'),
            onPressed: () => Navigator.of(context).pushNamed('/favorites'),
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
          ),
          IconButton(
            tooltip: AppStrings.t('notifications'),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.primaryBlue),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _headerCard(p),
              const SizedBox(height: 14),
              _modeToggle(p),
              if (!_canSelfDrop)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(AppStrings.t('selfDropUnavailable'),
                      style: TextStyle(color: p.textSecondary, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                _chip(categoryLabel(widget.provider.category),
                    const Color(0xFF1E9E52),
                    icon: Icons.verified_outlined),
                _chip(AppStrings.t(_selfDrop ? 'selfDrop' : 'appointment'),
                    AppColors.primaryBlue),
              ]),
              const SizedBox(height: 12),
              if (_selfDrop)
                ..._selfDropSection(p)
              else
                ..._appointmentSection(p),
              const SizedBox(height: 18),
              _serviceCard(p),
              if (_selfDrop && _hasFees) ...[
                const SizedBox(height: 14),
                _feesCard(p),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: AppStrings.t('bookingNote'),
                    hintText: AppStrings.t('bookingNoteHint'),
                    filled: true,
                    fillColor: p.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: p.border))),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: p.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(AppStrings.t('finalPriceNote'),
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(p),
    );
  }

  List<Widget> _selfDropSection(AppPalette p) => [
        _workshopCard(p),
        const SizedBox(height: 12),
        _technicianRow(p),
        const SizedBox(height: 12),
        _selfDropCard(p),
        if (_travelFee != null) ...[
          const SizedBox(height: 12),
          _saveBanner(p),
        ],
        const SizedBox(height: 18),
        Text(AppStrings.t('arrivalTimeWindow'),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary)),
        const SizedBox(height: 10),
        _buildArrivalOptions(p),
        if (_arrival == _Arrival.custom) ...[
          const SizedBox(height: 14),
          _buildCalendar(p),
          const SizedBox(height: 14),
          _label(p, AppStrings.t('bookingAvailableTime')),
          const SizedBox(height: 8),
          _buildTimeSlots(p),
        ],
      ];

  List<Widget> _appointmentSection(AppPalette p) => [
        _technicianRow(p),
        const SizedBox(height: 14),
        _buildCalendar(p),
        const SizedBox(height: 16),
        _label(p, AppStrings.t('bookingAvailableTime')),
        const SizedBox(height: 8),
        _buildTimeSlots(p),
        const SizedBox(height: 16),
        _label(p, AppStrings.t('bookingAddress')),
        const SizedBox(height: 8),
        _pickerField(
            p,
            Icons.location_on_outlined,
            _address ?? AppStrings.t('chooseOnMap'),
            _address != null,
            _pickOnMap),
      ];

  Widget _chip(String text, Color color, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ]),
      );

  Widget _card(AppPalette p, Widget child,
          {Color? color, Color? border, EdgeInsets? padding}) =>
      Container(
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color ?? p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border ?? p.border),
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );

  /// "Air Conditioner | Professional", real distance + phone, avatar + name.
  Widget _headerCard(AppPalette p) {
    final provider = widget.provider;
    final photo = provider.photoUrl;
    final dist = _distanceLabel;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 6),
          Text('${categoryLabel(provider.category)} | ${provider.role}',
              style: TextStyle(fontSize: 15, color: p.textSecondary)),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 6, children: [
            if (dist != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 3),
                Text('$dist ${AppStrings.t('nearbyWord')}',
                    style: TextStyle(fontSize: 12.5, color: p.textPrimary)),
              ]),
            if (provider.phone.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.phone_rounded,
                    size: 15, color: AppColors.primaryBlue),
                const SizedBox(width: 3),
                Text(provider.phone,
                    style: TextStyle(fontSize: 12.5, color: p.textPrimary)),
              ]),
          ]),
        ]),
      ),
      const SizedBox(width: 12),
      Column(children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: .13),
          foregroundImage: photo == null || photo.isEmpty
              ? null
              : NetworkImage('${ApiClient.instance.baseUrl}$photo'),
          onForegroundImageError:
              photo == null || photo.isEmpty ? null : (_, __) {},
          child: const Icon(Icons.engineering_rounded,
              size: 36, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(provider.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary)),
        ),
      ]),
    ]);
  }

  /// Appointment | Self Drop pill toggle.
  Widget _modeToggle(AppPalette p) {
    Widget tab(bool selfDrop, IconData icon, String label) {
      final selected = _selfDrop == selfDrop;
      final enabled = !selfDrop || _canSelfDrop;
      return Expanded(
        child: GestureDetector(
          onTap: !enabled
              ? null
              : () => setState(() {
                    _selfDrop = selfDrop;
                    _scheduled = true;
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? p.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow:
                  selected ? [BoxShadow(color: p.shadow, blurRadius: 6)] : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 16,
                  color: !enabled
                      ? p.textSecondary.withValues(alpha: 0.4)
                      : selected
                          ? p.textPrimary
                          : p.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: !enabled
                          ? p.textSecondary.withValues(alpha: 0.4)
                          : selected
                              ? p.textPrimary
                              : p.textSecondary)),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
        tab(false, Icons.calendar_today_outlined, AppStrings.t('appointment')),
        tab(true, Icons.storefront_outlined, AppStrings.t('selfDrop')),
      ]),
    );
  }

  /// The technician's shop: their banner photo, real opening-hours badge,
  /// shop name and address.
  Widget _workshopCard(AppPalette p) {
    final provider = widget.provider;
    final banner = provider.bannerUrl;
    final (open, hoursText) = _hoursBadge;
    final title = provider.bannerTitle?.trim().isNotEmpty == true
        ? provider.bannerTitle!.trim()
        : provider.name;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 170,
        child: Stack(fit: StackFit.expand, children: [
          if (banner != null && banner.isNotEmpty)
            Image.network('${ApiClient.instance.baseUrl}$banner',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.primaryBlue))
          else
            Container(
              decoration: const BoxDecoration(gradient: AppColors.blueGradient),
              child: const Align(
                alignment: Alignment(0.8, 0),
                child: Icon(Icons.storefront_rounded,
                    size: 90, color: Colors.white24),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.35, 1],
              ),
            ),
          ),
          if (hoursText.isNotEmpty && hoursText != '—')
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (open != null) ...[
                    CircleAvatar(
                        radius: 3.5,
                        backgroundColor: open
                            ? const Color(0xFF1E9E52)
                            : const Color(0xFFE5484D)),
                    const SizedBox(width: 5),
                  ] else ...[
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textDark),
                    const SizedBox(width: 4),
                  ],
                  Text(hoursText,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ]),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(_dropOffAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.white70)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Technician + real contact button (calls their actual number).
  Widget _technicianRow(AppPalette p) {
    final provider = widget.provider;
    return _card(
      p,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.primaryBlue.withValues(alpha: 0.05),
      Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_outlined,
              size: 19, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(provider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
            Text(
                provider.ratingCount > 0
                    ? '${AppStrings.t('approvedTechnician')} • ★ ${provider.rating.toStringAsFixed(1)} (${provider.ratingCount})'
                    : AppStrings.t('approvedTechnician'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
          ]),
        ),
        if (provider.phone.isNotEmpty)
          IconButton.filledTonal(
            tooltip: AppStrings.t('call'),
            onPressed: () => launchUrl(Uri.parse('tel:${provider.phone}')),
            icon: const Icon(Icons.call_rounded, size: 18),
          ),
      ]),
    );
  }

  /// "Self Drop" + Change, what happens, and the shop address.
  Widget _selfDropCard(AppPalette p) {
    final dist = _distanceLabel;
    return _card(
      p,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(AppStrings.t('selfDrop'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: p.textPrimary)),
          ),
          TextButton(
            onPressed: () => setState(() => _selfDrop = false),
            child: Text(AppStrings.t('changeWord')),
          ),
        ]),
        Text(AppStrings.t('selfDropHowItWorks'),
            style: TextStyle(fontSize: 12, color: p.textSecondary)),
        const SizedBox(height: 12),
        InkWell(
          onTap: widget.provider.hasLocation
              ? () => Navigator.of(context)
                  .pushNamed('/directions', arguments: widget.provider)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 17, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_dropOffAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.textPrimary)),
              ),
              if (dist != null) ...[
                const SizedBox(width: 6),
                Text(dist,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary)),
              ],
              if (widget.provider.hasLocation) ...[
                const SizedBox(width: 6),
                const Icon(Icons.north_east_rounded,
                    size: 16, color: AppColors.primaryBlue),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  /// Pink "Save $X travel fee" banner - only when an admin has set a real
  /// standard travel fee for this category.
  Widget _saveBanner(AppPalette p) {
    const red = Color(0xFFD93A56);
    final bench = _pricing?.benchFee;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: red.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.savings_outlined, color: red, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '${AppStrings.t('saveWord')} ${_money(_travelFee!)} ${AppStrings.t('travelFeeBySelfDrop')}',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800, color: red)),
            const SizedBox(height: 3),
            Text(
                bench != null
                    ? '${AppStrings.t('benchFeePaidAtCounter')} (${_money(bench)})'
                    : AppStrings.t('noTravelFeeSelfDrop'),
                style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  /// The service being booked, with the technician's own feature bullets.
  Widget _serviceCard(AppPalette p) {
    final listing = widget.listing;
    final title = listing?.title ?? _serviceLabel(_service);
    final features = listing?.features ?? const <String>[];
    return _card(
      p,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: listing?.photoUrl != null
                ? Image.network(
                    '${ApiClient.instance.baseUrl}${listing!.photoUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.home_repair_service_rounded,
                        color: AppColors.primaryBlue))
                : const Icon(Icons.home_repair_service_rounded,
                    color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(
                  _startingPrice == null
                      ? categoryLabel(widget.provider.category)
                      : '${categoryLabel(widget.provider.category)} • ${AppStrings.t('startingFrom')} ${_money(_startingPrice!)}',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ]),
          ),
        ]),
        if (listing == null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _services
                .map((s) => ChoiceChip(
                      label: Text(_serviceLabel(s)),
                      selected: _service == s,
                      onSelected: (_) => setState(() => _service = s),
                      selectedColor: AppColors.primaryBlue,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          color: _service == s ? Colors.white : p.textPrimary),
                    ))
                .toList(),
          ),
        ] else if (features.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in features)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 13, color: Color(0xFF1E9E52)),
                    const SizedBox(width: 4),
                    Text(f,
                        style: TextStyle(fontSize: 11, color: p.textPrimary)),
                  ]),
                ),
            ],
          ),
        ],
      ]),
    );
  }

  static String _money(double v) =>
      '\$${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';

  /// Show the fee breakdown only when an admin actually configured a fee.
  bool get _hasFees => _pricing?.benchFee != null || _travelFee != null;

  /// DEPOSIT & WAIVER BREAKDOWN - the admin-set bench fee (paid at the
  /// counter at drop-off) and the standard travel fee Self Drop skips.
  Widget _feesCard(AppPalette p) {
    final bench = _pricing?.benchFee;
    final travel = _travelFee;
    const red = Color(0xFFD93A56);
    Widget line(String label, String value,
            {Color? color, bool bold = false, IconData? icon}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color ?? p.textSecondary),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: bold ? 14 : 12.5,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      color:
                          color ?? (bold ? p.textPrimary : p.textSecondary))),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 17 : 13,
                    fontWeight: FontWeight.w800,
                    color: color ?? p.textPrimary)),
          ]),
        );
    return _card(
      p,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.t('depositBreakdownCaps'),
            style: TextStyle(
                fontSize: 11.5,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w800,
                color: p.textSecondary)),
        const SizedBox(height: 8),
        if (bench != null) line(AppStrings.t('benchFee'), _money(bench)),
        if (travel != null)
          line(AppStrings.t('selfDropTravelWaiver'), '-${_money(travel)}',
              color: red, icon: Icons.local_shipping_outlined),
        if (bench != null) ...[
          Divider(height: 18, color: p.border),
          line(AppStrings.t('totalDepositDue'), _money(bench), bold: true),
          Text(AppStrings.t('payableAtCounter'),
              style: TextStyle(fontSize: 11, color: p.textSecondary)),
        ],
      ]),
    );
  }

  /// Arrival Time Window - 2x2 grid.
  Widget _buildArrivalOptions(AppPalette p) {
    final afternoonIsToday = _nextAfternoon.day == DateTime.now().day;
    final options = <(_Arrival, String, String, IconData?)>[
      (
        _Arrival.now,
        AppStrings.t('arriveImmediately'),
        AppStrings.t('headOverNow'),
        null
      ),
      (
        _Arrival.inOneHour,
        AppStrings.t('arriveInOneHour'),
        '${AppStrings.t('aroundWord')} ${TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))).format(context)}',
        null
      ),
      (
        _Arrival.afternoon,
        AppStrings.t(
            afternoonIsToday ? 'arriveAfternoon' : 'arriveTomorrowAfternoon'),
        TimeOfDay.fromDateTime(_nextAfternoon).format(context),
        null
      ),
      (
        _Arrival.custom,
        AppStrings.t('customSlot'),
        _arrival == _Arrival.custom && _when != null
            ? '${_monthNames[_when!.month - 1].substring(0, 3)} ${_when!.day}, ${TimeOfDay.fromDateTime(_when!).format(context)}'
            : AppStrings.t('selectTime'),
        Icons.schedule_rounded
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (key, title, detail, icon) in options)
            SizedBox(
              width: (constraints.maxWidth - 10) / 2,
              child: Material(
                color: _arrival == key ? AppColors.primaryBlue : p.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: _arrival == key
                            ? AppColors.primaryBlue
                            : p.border)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _arrival = key),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _arrival == key
                                          ? Colors.white
                                          : p.textPrimary)),
                              const SizedBox(height: 3),
                              Text(detail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _arrival == key
                                          ? Colors.white70
                                          : p.textSecondary)),
                            ]),
                      ),
                      if (_arrival == key)
                        const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                      else if (icon != null)
                        Icon(icon, size: 16, color: p.textSecondary),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Total Estimated (real starting price; for Self Drop the standard travel
  /// fee a home visit would add is shown struck through) + Confirm.
  Widget _bottomBar(AppPalette p) {
    final start = _startingPrice;
    final travel = _travelFee;
    final showWaiver = _selfDrop && travel != null && start != null;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (start != null)
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t('totalEstimated'),
                            style: TextStyle(
                                fontSize: 12, color: p.textSecondary)),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('${_money(start)}+',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: p.textPrimary)),
                              if (showWaiver) ...[
                                const SizedBox(width: 6),
                                Text(_money(start + travel),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: p.textSecondary,
                                        decoration:
                                            TextDecoration.lineThrough)),
                              ],
                            ]),
                      ]),
                ),
                if (showWaiver)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E9E52).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                        '${AppStrings.t('travelFeeWaivedShort')} -${_money(travel)}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E9E52))),
                  ),
              ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _ready ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w800),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(
                      _submitting
                          ? AppStrings.t('sending')
                          : AppStrings.t(
                              _selfDrop ? 'confirmDropOff' : 'confirmBooking'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!_submitting) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(AppPalette p, String text) => Text(text,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildCalendar(AppPalette p) {
    final today = DateTime.now();
    final firstOfMonth = _visibleMonth;
    final lastBookable = today.add(const Duration(days: 60));
    final canGoBack = _visibleMonth.isAfter(DateTime(today.year, today.month));
    final canGoForward = DateTime(_visibleMonth.year, _visibleMonth.month + 1)
        .isBefore(DateTime(lastBookable.year, lastBookable.month + 1));
    final daysInMonth =
        DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    // Monday-first offset (weekday: Mon=1 .. Sun=7).
    final leadingBlanks = firstOfMonth.weekday - 1;

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: canGoBack
                    ? () => setState(() => _visibleMonth =
                        DateTime(_visibleMonth.year, _visibleMonth.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                  '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: p.textPrimary)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: canGoForward
                    ? () => setState(() => _visibleMonth =
                        DateTime(_visibleMonth.year, _visibleMonth.month + 1))
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: [
              for (final w in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(w,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.textSecondary)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                Builder(builder: (context) {
                  final day =
                      DateTime(_visibleMonth.year, _visibleMonth.month, d);
                  final isPast = day
                      .isBefore(DateTime(today.year, today.month, today.day));
                  final isTooFar = day.isAfter(lastBookable);
                  final disabled = isPast || isTooFar;
                  final selected = _date != null && _sameDay(_date!, day);
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: disabled
                        ? null
                        : () => setState(() {
                              _date = day;
                              // A slot that's already passed today can't stay picked.
                              if (_time != null &&
                                  _sameDay(day, today) &&
                                  _time!.hour <= today.hour) {
                                _time = null;
                              }
                            }),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryBlue : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('$d',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.white
                                  : disabled
                                      ? p.textSecondary.withValues(alpha: 0.35)
                                      : p.textPrimary)),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(AppPalette p) {
    final now = DateTime.now();
    final isToday = _date != null && _sameDay(_date!, now);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      // Hide slots already in the past when today is picked.
      children: _timeSlots.where((t) => !isToday || t.hour > now.hour).map((t) {
        final selected = _time == t;
        return ChoiceChip(
          label: Text(t.format(context)),
          selected: selected,
          onSelected: (_) => setState(() => _time = t),
          showCheckmark: false,
          selectedColor: AppColors.primaryBlue,
          backgroundColor: p.surface,
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : p.textPrimary,
          ),
          side: BorderSide(color: selected ? AppColors.primaryBlue : p.border),
        );
      }).toList(),
    );
  }

  Widget _pickerField(AppPalette p, IconData icon, String label, bool set,
          VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: p.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: set ? p.textPrimary : p.textSecondary,
                        fontWeight: set ? FontWeight.w600 : FontWeight.w400)),
              ),
            ],
          ),
        ),
      );
}

class _BookingDoneDialog extends StatelessWidget {
  const _BookingDoneDialog(
      {required this.provider, required this.service, required this.address});
  final String provider;
  final String service;
  final String address;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: AppColors.primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.t('bookingDone'),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            const SizedBox(height: 6),
            Text(
              '$service · $provider',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13, color: p.textSecondary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    address,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.t('bookingDoneBody'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: AppStrings.t('trackBooking'),
                background: AppColors.primaryBlue,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.t('done')),
            ),
          ],
        ),
      ),
    );
  }
}
