import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/service_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

/// "Book Now" flow for a provider: pick a service, a day and time, add a note,
/// confirm. Local-only for now (no bookings endpoint) — ends on a success
/// dialog.
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
  static const _services = ['Repair', 'Clean', 'Installation', 'Inspection'];
  final _note = TextEditingController();
  String _service = _services.first;
  DateTime? _date;
  TimeOfDay? _time;
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _ready => _date != null && _time != null && !_submitting;

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

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop(); // close the sheet
    await showDialog<void>(
      context: context,
      builder: (_) => _BookingDoneDialog(
        provider: widget.provider.name,
        service: _service,
      ),
    );
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
                '${widget.provider.name} · ${widget.provider.category}',
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
              const SizedBox(height: 18),

              _label(p, AppStrings.t('bookingService')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((s) {
                  final sel = s == _service;
                  return ChoiceChip(
                    label: Text(s),
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
  const _BookingDoneDialog({required this.provider, required this.service});
  final String provider;
  final String service;

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
            Text(
              AppStrings.t('bookingDoneBody'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              child: PrimaryButton(
                label: AppStrings.t('done'),
                background: AppColors.primaryBlue,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
