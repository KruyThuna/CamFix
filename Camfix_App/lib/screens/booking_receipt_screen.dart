import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/service_quote.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart' show Booking;
import '../theme/app_theme.dart';
import 'payment_summary_screen.dart' show PaymentBreakdown;
import 'services_screen.dart' show categoryLabel;

/// Booking Receipt (mockup): the booking, its technician, when/where, and the
/// real cost breakdown from the accepted quote. Every line comes from the
/// backend - the "Paid" badge only shows when a payment was actually recorded,
/// and there are no promo/discount lines because no promo system exists.
///
/// Route argument: the booking (job) id.
class BookingReceiptScreen extends StatefulWidget {
  const BookingReceiptScreen({super.key});

  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen> {
  int? _id;
  Booking? _booking;
  ServiceQuote? _quote;
  Payment? _payment;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_id != null) return;
    _id = ModalRoute.of(context)!.settings.arguments as int;
    _load();
  }

  Future<void> _load() async {
    try {
      final api = BookingsApi.instance;
      final results = await Future.wait([
        api.getOne(_id!),
        api.quotes(_id!),
        api.payment(_id!).catchError((_) => null),
      ]);
      final quotes = results[1] as List<ServiceQuote>;
      final payment = results[2] as Payment?;
      ServiceQuote? quote;
      for (final q in quotes) {
        final matchesPayment = payment != null && q.id == payment.quoteId;
        if (matchesPayment || (quote == null && q.isAccepted)) quote = q;
      }
      if (!mounted) return;
      setState(() {
        _booking = results[0] as Booking;
        _quote = quote;
        _payment = payment;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // --- formatting -----------------------------------------------------------

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _date(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';

  /// "Repair - booked via app (customer picked X). Note: ..." -> ("Repair", "...").
  static (String, String?) _splitDescription(Booking b) {
    final d = b.description;
    final cut = d.indexOf(' - booked via app');
    final title = cut > 0 ? d.substring(0, cut) : categoryLabel(b.category);
    final noteAt = d.indexOf('. Note: ');
    final note = noteAt >= 0 ? d.substring(noteAt + 8).trim() : null;
    return (title, note == null || note.isEmpty ? null : note);
  }

  String _typeLabel(Booking b) => switch (b.bookingType) {
        'SELF_DROP' => AppStrings.t('selfDrop'),
        'SCHEDULED' => AppStrings.t('appointment'),
        _ => AppStrings.t('bookNowChip'),
      };

  String _methodLabel(Payment p) => switch (p.paymentMethod) {
        'APPLE_PAY' => AppStrings.t('applePay'),
        'PAYPAL' => AppStrings.t('paypalWallet'),
        'KHQR' => AppStrings.t('khqrTitle'),
        'CARD' => 'Card •••• ${p.cardLast4 ?? ''}',
        _ => p.paymentMethod,
      };

  /// Plain-text copy of the receipt for sharing (no share plugin is
  /// installed, so it goes to the clipboard).
  Future<void> _copyReceipt() async {
    final b = _booking!;
    final q = _quote;
    final (title, _) = _splitDescription(b);
    final lines = <String>[
      'CAM FIX - ${AppStrings.t('bookingReceipt')}',
      if (_payment != null)
        '${AppStrings.t('serviceId')}: #${_payment!.serviceRef}',
      '$title (${categoryLabel(b.category)})',
      if (b.technicianName != null) b.technicianName!,
      '${_date(b.when)} ${_time(b.when)}',
      if ((b.address ?? '').isNotEmpty) b.address!,
      if (q != null) ...[
        '',
        '${AppStrings.t('quoteInspectionFee')}: ${_money(q.inspectionFee)}',
        '${AppStrings.t('quoteLaborCost')}: ${_money(q.laborCost)}',
        '${AppStrings.t('quotePartsCost')}: ${_money(q.partsCost)}',
        if (q.travelFee > 0)
          '${AppStrings.t('quoteTravelFee')}: ${_money(q.travelFee)}',
        '${AppStrings.t('totalAmount')}: ${_money(_payment?.totalAmount ?? PaymentBreakdown.fromQuote(q).total)}',
        _payment != null
            ? AppStrings.t('paidBadge')
            : AppStrings.t('unpaidBadge'),
      ],
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppStrings.t('receiptCopied'))));
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final b = _booking;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(AppStrings.t('bookingReceipt'),
            style: TextStyle(
                color: p.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: p.textPrimary),
        actions: [
          if (b != null)
            IconButton(
              tooltip: AppStrings.t('bookingReceipt'),
              onPressed: _copyReceipt,
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: b == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textSecondary)),
                    ))
          : RefreshIndicator(
              onRefresh: _load,
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _serviceCard(p, b),
                      if (b.technicianName != null) ...[
                        const SizedBox(height: 12),
                        _technicianCard(p, b),
                      ],
                      const SizedBox(height: 16),
                      _infoRow(
                        p,
                        Icons.calendar_month_rounded,
                        AppStrings.t('dateWindow'),
                        _date(b.when),
                        _time(b.when),
                      ),
                      if ((b.address ?? '').isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _infoRow(
                          p,
                          b.isSelfDrop
                              ? Icons.storefront_rounded
                              : Icons.location_on_rounded,
                          AppStrings.t(b.isSelfDrop
                              ? 'dropOffLocation'
                              : 'serviceAddress'),
                          b.address!,
                          null,
                        ),
                      ],
                      if (b.completedAt != null) ...[
                        const SizedBox(height: 14),
                        _infoRow(
                          p,
                          Icons.task_alt_rounded,
                          AppStrings.t('completedOn'),
                          _date(b.completedAt!),
                          _time(b.completedAt!),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _dashedDivider(p),
                      const SizedBox(height: 16),
                      _breakdown(p),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _card(AppPalette p, Widget child, {Color? color}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color ?? p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: child,
      );

  Widget _chip(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _serviceCard(AppPalette p, Booking b) {
    final (title, note) = _splitDescription(b);
    return _card(
      p,
      color: AppColors.primaryBlue.withValues(alpha: 0.06),
      Row(children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.home_repair_service_rounded,
              color: AppColors.primaryBlue, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(categoryLabel(b.category), const Color(0xFF1E9E52),
                  const Color(0xFFE8F8F1)),
              _chip(_typeLabel(b), p.textSecondary, p.surfaceAlt),
            ]),
            const SizedBox(height: 6),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _technicianCard(AppPalette p, Booking b) {
    return _card(
      p,
      color: AppColors.primaryBlue.withValues(alpha: 0.06),
      Row(children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryBlue,
          child: Icon(Icons.engineering_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.technicianName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
            const SizedBox(height: 4),
            _chip(AppStrings.t('approvedTechnician'), AppColors.primaryBlue,
                AppColors.primaryBlue.withValues(alpha: 0.12)),
          ]),
        ),
        if ((b.technicianPhone ?? '').isNotEmpty)
          _roundAction(Icons.call_rounded,
              () => launchUrl(Uri.parse('tel:${b.technicianPhone}'))),
      ]),
    );
  }

  Widget _roundAction(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryBlue),
        ),
      );

  Widget _infoRow(AppPalette p, IconData icon, String label, String value,
      String? trailing) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryBlue),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: p.textSecondary)),
          const SizedBox(height: 2),
          Text.rich(TextSpan(children: [
            TextSpan(
                text: value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
            if (trailing != null)
              TextSpan(
                  text: '  $trailing',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
          ])),
        ]),
      ),
    ]);
  }

  Widget _dashedDivider(AppPalette p) => LayoutBuilder(
        builder: (_, c) {
          final n = (c.maxWidth / 8).floor();
          return Row(
            children: List.generate(
              n,
              (_) => Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: p.border,
                ),
              ),
            ),
          );
        },
      );

  Widget _breakdown(AppPalette p) {
    final q = _quote;
    final pay = _payment;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(AppStrings.t('paymentBreakdown'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: p.textPrimary)),
        ),
        if (q != null)
          pay != null
              ? _chip('✓ ${AppStrings.t('paidBadge')}', const Color(0xFF1E9E52),
                  const Color(0xFFE8F8F1))
              : _chip(AppStrings.t('unpaidBadge'), const Color(0xFFB26A00),
                  const Color(0xFFFFF3DD)),
      ]),
      const SizedBox(height: 12),
      if (q == null)
        Text(AppStrings.t('receiptNoQuote'),
            style: TextStyle(fontSize: 12.5, color: p.textSecondary))
      else ...[
        _line(p, AppStrings.t('quoteInspectionFee'), q.inspectionFee),
        _line(p, AppStrings.t('quoteLaborCost'), q.laborCost),
        _line(p, AppStrings.t('quotePartsCost'), q.partsCost),
        if (q.travelFee > 0)
          _line(p, AppStrings.t('quoteTravelFee'), q.travelFee),
        _line(p, AppStrings.t('subtotal'), pay?.baseAmount ?? q.totalAmount,
            strong: true),
        ..._chargesLines(p, q, pay),
        const SizedBox(height: 8),
        _dashedDivider(p),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Text(AppStrings.t('totalAmount'),
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary)),
          ),
          Text(_money(pay?.totalAmount ?? PaymentBreakdown.fromQuote(q).total),
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlue)),
        ]),
        if (pay != null) ...[
          const SizedBox(height: 14),
          _card(
            p,
            Column(children: [
              _kv(p, AppStrings.t('serviceId'), '#${pay.serviceRef}'),
              _kv(p, AppStrings.t('paymentMethodLabel'), _methodLabel(pay)),
              if (pay.createdAt != null)
                _kv(p, AppStrings.t('paidOn'),
                    '${_date(pay.createdAt!)}  ${_time(pay.createdAt!)}'),
            ]),
          ),
        ],
      ],
    ]);
  }

  /// Platform fee + tax: the recorded amounts once paid, otherwise the same
  /// formula the backend will apply at payment time.
  List<Widget> _chargesLines(AppPalette p, ServiceQuote q, Payment? pay) {
    final est = PaymentBreakdown.fromQuote(q);
    return [
      _line(p, AppStrings.t('platformProcessing'),
          pay?.platformFee ?? est.platformFee),
      _line(p, AppStrings.t('taxes85'), pay?.taxAmount ?? est.tax),
    ];
  }

  Widget _line(AppPalette p, String label, double amount,
          {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                    color: strong ? p.textPrimary : p.textSecondary)),
          ),
          Text(_money(amount),
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary)),
        ]),
      );

  Widget _kv(AppPalette p, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
              child: Text(k,
                  style: TextStyle(fontSize: 12, color: p.textSecondary))),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary)),
          ),
        ]),
      );
}
