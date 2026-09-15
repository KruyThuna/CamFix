import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../services/api_client.dart';
import '../services/bookings_store.dart';
import '../services/notifications_store.dart';
import '../services/service_prices_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import 'services_screen.dart' show categoryLabel;

/// "Book Now" flow for a provider: pick a service, a day and time, add a note,
/// confirm. Sends the booking to the backend (`POST /api/bookings`, which
/// creates a job + notifications) and ends on a success dialog.
Future<void> showBookingSheet(BuildContext context, ServiceProvider p) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BookingSheet(provider: p),
  );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.provider});
  final ServiceProvider provider;

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
  final _note = TextEditingController();
  String _service = _services.first;
  bool _scheduled = false; // false = book now (Immediate), true = pick a time
  DateTime? _date;
  TimeOfDay? _time;
  String? _address; // where the technician should come — "lat, lng" or typed
  LatLng? _pickedLatLng;
  bool _submitting = false;
  double? _startingPrice;

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
    // "Starting from $X" — a catalog estimate, never the final repair cost
    // (that comes later as a real ServiceQuote once a technician inspects).
    ServicePricesApi.instance.startingPriceFor(widget.provider.category).then((p) {
      if (mounted) setState(() => _startingPrice = p);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _ready =>
      _address != null &&
      !_submitting &&
      (!_scheduled || (_date != null && _time != null));

  static LatLng? _parseLatLng(String s) {
    final m = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(s);
    return m == null
        ? null
        : LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
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

    final when = _scheduled
        ? DateTime(
            _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute)
        : DateTime.now();

    Map<String, dynamic> response;
    try {
      response = await ApiClient.instance.postJson(
        '/api/bookings',
        {
          'category': widget.provider.category,
          'service': _service,
          'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          'address': _address,
          'lat': _pickedLatLng?.latitude,
          'lng': _pickedLatLng?.longitude,
          'scheduledAt': _scheduled ? when.toUtc().toIso8601String() : null,
          'bookingType': _scheduled ? 'SCHEDULED' : 'IMMEDIATE',
          'providerName': widget.provider.name,
          if (widget.provider.technicianId != null)
            'technicianId': widget.provider.technicianId,
        },
        withAuth: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.t('bookingFailed')}: ${e.message}')),
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
        address: _address!,
      ),
    );
    if (track == true && jobId != null) {
      navigator.pushNamed('/booking-tracking', arguments: jobId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final dateLabel = _date == null
        ? AppStrings.t('pickDate')
        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-'
            '${_date!.day.toString().padLeft(2, '0')}';
    final timeLabel =
        _time == null ? AppStrings.t('pickTime') : _time!.format(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(AppStrings.t('bookingTitle'),
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 4),
              Text(
                '${widget.provider.name} · ${categoryLabel(widget.provider.category)}',
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
              if (_startingPrice != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 15, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${AppStrings.t('startingFrom')} \$${_startingPrice!.toStringAsFixed(0)} '
                          '— ${AppStrings.t('finalPriceNote')}',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              _label(p, AppStrings.t('bookingService')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((s) {
                  final sel = s == _service;
                  return ChoiceChip(
                    label: Text(_serviceLabel(s)),
                    selected: sel,
                    onSelected: (_) => setState(() => _service = s),
                    showCheckmark: false,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: p.surfaceAlt,
                    labelStyle: TextStyle(
                      color: sel ? AppColors.white : p.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: p.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              _label(p, AppStrings.t('bookingWhen')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _choiceCard(
                      p,
                      icon: Icons.flash_on_rounded,
                      label: AppStrings.t('bookNowChip'),
                      subtitle: AppStrings.t('bookNowChipSub'),
                      selected: !_scheduled,
                      onTap: () => setState(() => _scheduled = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _choiceCard(
                      p,
                      icon: Icons.event_available_rounded,
                      label: AppStrings.t('scheduleChip'),
                      subtitle: AppStrings.t('scheduleChipSub'),
                      selected: _scheduled,
                      onTap: () => setState(() => _scheduled = true),
                    ),
                  ),
                ],
              ),
              if (_scheduled) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _pickerField(p, Icons.calendar_today_outlined,
                          dateLabel, _date != null, _pickDate),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _pickerField(p, Icons.schedule, timeLabel,
                          _time != null, _pickTime),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              _label(p, AppStrings.t('bookingAddress')),
              const SizedBox(height: 8),
              _pickerField(
                p,
                Icons.location_on_outlined,
                _address ?? AppStrings.t('chooseOnMap'),
                _address != null,
                _pickOnMap,
              ),
              const SizedBox(height: 18),

              _label(p, AppStrings.t('bookingNote')),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: TextField(
                  controller: _note,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: p.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppStrings.t('bookingNoteHint'),
                    hintStyle:
                        TextStyle(color: p.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              PrimaryButton(
                label: _submitting
                    ? AppStrings.t('sending')
                    : AppStrings.t('confirmBooking'),
                background: AppColors.primaryBlue,
                onPressed: _ready ? _confirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(AppPalette p, String text) => Text(text,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary));

  Widget _choiceCard(
    AppPalette p, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.10)
              : p.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primaryBlue : p.border,
              width: selected ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? AppColors.primaryBlue : p.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? AppColors.primaryBlue : p.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: p.textSecondary)),
          ],
        ),
      ),
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
                        fontWeight:
                            set ? FontWeight.w600 : FontWeight.w400)),
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
