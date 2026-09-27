import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart' show Booking;
import '../theme/app_theme.dart';
import 'services_screen.dart' show categoryLabel;

enum _Sort { newest, oldest, amountHigh, amountLow }

/// Total Spend / Service History (mockup), opened from the Profile "Total
/// Spend" tile. Everything is computed from the customer's real bookings
/// (`GET /api/bookings/mine`) and real recorded payments
/// (`GET /api/bookings/payments/mine`) - no invented trends or insights.
class TotalSpendScreen extends StatefulWidget {
  const TotalSpendScreen({super.key});

  @override
  State<TotalSpendScreen> createState() => _TotalSpendScreenState();
}

class _TotalSpendScreenState extends State<TotalSpendScreen> {
  List<Booking> _bookings = const [];
  Map<int, Payment> _paymentByJob = const {};
  bool _loading = true;
  String? _error;

  bool _showActive = true;
  String? _category; // null = All
  _Sort _sort = _Sort.newest;

  final _breakdownController = PageController(viewportFraction: 0.86);
  int _breakdownPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _breakdownController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = BookingsApi.instance;
      final results = await Future.wait([api.listMine(), api.myPayments()]);
      final payments = results[1] as List<Payment>;
      final byJob = <int, Payment>{};
      for (final pay in payments) {
        // Newest first from the API - keep the first seen per job.
        byJob.putIfAbsent(pay.jobId, () => pay);
      }
      if (!mounted) return;
      setState(() {
        _bookings = results[0] as List<Booking>;
        _paymentByJob = byJob;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  // --- derived data -----------------------------------------------------

  double get _totalSpent =>
      _paymentByJob.values.fold(0, (s, p) => s + p.totalAmount);

  int get _jobsDone => _bookings.where((b) => b.status == 'COMPLETED').length;

  /// category -> amount paid, biggest first.
  List<MapEntry<String, double>> get _byCategory {
    final totals = <String, double>{};
    for (final b in _bookings) {
      final pay = _paymentByJob[b.id];
      if (pay == null) continue;
      totals[b.category] = (totals[b.category] ?? 0) + pay.totalAmount;
    }
    return totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<String> get _categories {
    final seen = <String>{};
    return [
      for (final b in _bookings)
        if (seen.add(b.category)) b.category
    ];
  }

  List<Booking> get _visible {
    final list = _bookings
        .where((b) => b.isOpen == _showActive)
        .where((b) => _category == null || b.category == _category)
        .toList();
    double amount(Booking b) => _paymentByJob[b.id]?.totalAmount ?? -1;
    list.sort((a, b) => switch (_sort) {
          _Sort.newest => b.when.compareTo(a.when),
          _Sort.oldest => a.when.compareTo(b.when),
          _Sort.amountHigh => amount(b).compareTo(amount(a)),
          _Sort.amountLow => amount(a).compareTo(amount(b)),
        });
    return list;
  }

  // --- formatting -------------------------------------------------------

  static String _money(double v) => '\$${v.toStringAsFixed(2)}';

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
  static String _date(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static IconData _icon(String c) => switch (c) {
        'Electrical' => Icons.bolt_rounded,
        'Appliance Repair' => Icons.handyman_rounded,
        'Motorcycle' => Icons.two_wheeler_rounded,
        'Car' => Icons.directions_car_filled_rounded,
        'Water network' => Icons.plumbing_rounded,
        _ => Icons.ac_unit_rounded,
      };

  static String _serviceTitle(Booking b) {
    final cut = b.description.indexOf(' - booked via app');
    return cut > 0
        ? b.description.substring(0, cut)
        : categoryLabel(b.category);
  }

  String _statusLabel(Booking b) => AppStrings.t(switch (b.status) {
        'REQUESTED' => 'stepPending',
        'ASSIGNED' => 'stepAccepted',
        'ON_THE_WAY' => b.isSelfDrop ? 'stepReadyForDropOff' : 'stepOnTheWay',
        'ARRIVED' => b.isSelfDrop ? 'stepItemReceived' : 'stepArrived',
        'QUOTE_PENDING' => 'stepQuotePending',
        'IN_PROGRESS' => 'stepInProgress',
        'COMPLETED' => 'stepCompleted',
        _ => 'statusCancelled',
      });

  String _methodLabel(Payment p) => switch (p.paymentMethod) {
        'APPLE_PAY' => AppStrings.t('applePay'),
        'PAYPAL' => AppStrings.t('paypalWallet'),
        'KHQR' => AppStrings.t('khqrTitle'),
        'CARD' => 'Card •••• ${p.cardLast4 ?? ''}',
        _ => p.paymentMethod,
      };

  // --- UI ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        title: Text(AppStrings.t('totalSpendTitle'),
            style: TextStyle(
                color: p.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _bookings.isEmpty
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary)),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: AppLayout.maxPhoneWidth),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: _heroCard(),
                          ),
                          const SizedBox(height: 20),
                          _breakdownSection(p),
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _historyHeader(p),
                          ),
                          const SizedBox(height: 12),
                          _categoryChips(p),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _sortRow(p),
                          ),
                          const SizedBox(height: 12),
                          ..._historyList(p),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _heroCard() {
    Widget glass(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1FA2FF), Color(0xFF12D8C4)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.t('serviceHistory'),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(AppStrings.t('serviceHistorySub'),
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
        const SizedBox(height: 16),
        Row(children: [
          glass(AppStrings.t('totalSpentCaps'), _money(_totalSpent)),
          const SizedBox(width: 10),
          glass(AppStrings.t('jobsDoneCaps'), '$_jobsDone'),
        ]),
      ]),
    );
  }

  Widget _breakdownSection(AppPalette p) {
    final cats = _byCategory;
    final total = _totalSpent;
    final paidCount = _paymentByJob.length;
    final pages = 1 + cats.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.t('spendingBreakdown'),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(AppStrings.t('spendingBreakdownSub'),
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            ]),
          ),
          if (cats.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                  '${cats.length} ${AppStrings.t(cats.length == 1 ? 'categoryWord' : 'categoriesWord')}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 132,
        child: PageView.builder(
          controller: _breakdownController,
          padEnds: false,
          onPageChanged: (i) => setState(() => _breakdownPage = i),
          itemCount: pages,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6),
            child: i == 0
                ? _breakdownCard(
                    p,
                    header: Text(AppStrings.t('overviewCaps'),
                        style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                            color: p.textSecondary)),
                    amount: total,
                    caption:
                        '${AppStrings.t('acrossWord')} $paidCount ${AppStrings.t('paidServices')}',
                    fraction: paidCount == 0 ? 0 : 1,
                  )
                : _breakdownCard(
                    p,
                    header: Row(children: [
                      Icon(_icon(cats[i - 1].key),
                          size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(categoryLabel(cats[i - 1].key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary)),
                      ),
                    ]),
                    amount: cats[i - 1].value,
                    caption: total == 0
                        ? ''
                        : '${(cats[i - 1].value / total * 100).toStringAsFixed(1)}% ${AppStrings.t('ofTotalSpending')}',
                    fraction: total == 0 ? 0 : cats[i - 1].value / total,
                  ),
          ),
        ),
      ),
      if (pages > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages, (i) {
            final active = i == _breakdownPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryBlue
                    : p.textSecondary.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    ]);
  }

  Widget _breakdownCard(AppPalette p,
      {required Widget header,
      required double amount,
      required String caption,
      required double fraction}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        header,
        const SizedBox(height: 8),
        Text(_money(amount),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: p.textPrimary)),
        const SizedBox(height: 2),
        Text(caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: p.textSecondary)),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1).toDouble(),
            minHeight: 5,
            backgroundColor: p.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
          ),
        ),
      ]),
    );
  }

  Widget _historyHeader(AppPalette p) {
    Widget seg(String label, bool active) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showActive = active),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _showActive == active ? p.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: _showActive == active
                    ? [BoxShadow(color: p.shadow, blurRadius: 6)]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _showActive == active
                          ? AppColors.primaryBlue
                          : p.textSecondary)),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(AppStrings.t('bookingHistory'),
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: p.textPrimary)),
      const SizedBox(height: 2),
      Text(AppStrings.t('bookingHistorySub'),
          style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(children: [
          seg(AppStrings.t('activeTab'), true),
          seg(AppStrings.t('completedTab'), false),
        ]),
      ),
    ]);
  }

  Widget _categoryChips(AppPalette p) {
    final cats = _categories;
    Widget chip(String label, String? value) {
      final sel = _category == value;
      return ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _category = value),
        showCheckmark: false,
        selectedColor: const Color(0xFF1FA2FF),
        backgroundColor: p.surface,
        labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : p.textPrimary),
        side: BorderSide(color: sel ? const Color(0xFF1FA2FF) : p.border),
        shape: const StadiumBorder(),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(AppStrings.t('allFilter'), null),
          for (final c in cats) ...[
            const SizedBox(width: 8),
            chip(categoryLabel(c), c),
          ],
        ],
      ),
    );
  }

  Widget _sortRow(AppPalette p) {
    Widget pill(IconData icon, String label, List<(_Sort, String)> options) =>
        PopupMenuButton<_Sort>(
          onSelected: (s) => setState(() => _sort = s),
          itemBuilder: (_) => [
            for (final o in options)
              PopupMenuItem(value: o.$1, child: Text(o.$2)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: p.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: p.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: p.textSecondary),
            ]),
          ),
        );
    final newest = AppStrings.t('sortNewest');
    final oldest = AppStrings.t('sortOldest');
    final high = AppStrings.t('sortHighLow');
    final low = AppStrings.t('sortLowHigh');
    final dateLabel = _sort == _Sort.oldest ? oldest : newest;
    final amountLabel = _sort == _Sort.amountLow ? low : high;
    return Row(children: [
      pill(Icons.calendar_today_rounded,
          '${AppStrings.t('dateWord')}: $dateLabel', [
        (_Sort.newest, newest),
        (_Sort.oldest, oldest),
      ]),
      const Spacer(),
      pill(Icons.sort_rounded, '${AppStrings.t('amountWord')}: $amountLabel', [
        (_Sort.amountHigh, high),
        (_Sort.amountLow, low),
      ]),
    ]);
  }

  List<Widget> _historyList(AppPalette p) {
    final list = _visible;
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          child: Text(
              AppStrings.t(_showActive ? 'noActiveBookings' : 'noPastBookings'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary)),
        ),
      ];
    }
    return [
      for (final b in list)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _bookingCard(p, b),
        ),
    ];
  }

  Widget _bookingCard(AppPalette p, Booking b) {
    final pay = _paymentByJob[b.id];
    final cancelled = b.status == 'CANCELLED';
    Widget meta(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Icon(icon, size: 15, color: const Color(0xFFF5A623)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: p.textPrimary)),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1DC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(categoryLabel(b.category).toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD9822B))),
          ),
          const Spacer(),
          if (pay != null)
            Text(_money(pay.totalAmount),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: p.textPrimary))
          else
            Text(_statusLabel(b),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cancelled ? Colors.red : AppColors.primaryBlue)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(b.category),
                color: const Color(0xFFF5A623), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  b.technicianName ?? AppStrings.t('waitingForTechnicianShort'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 2),
              Text(_serviceTitle(b),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
            ]),
          ),
        ]),
        Divider(height: 22, color: p.border),
        meta(Icons.calendar_month_outlined, _date(b.when)),
        if ((b.address ?? '').isNotEmpty)
          meta(
              b.isSelfDrop
                  ? Icons.storefront_outlined
                  : Icons.location_on_outlined,
              b.address!),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pay != null
                    ? [
                        Text(
                            '${AppStrings.t('invoiceCaps')} #${pay.serviceRef}',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w700,
                                color: p.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                            '● ${AppStrings.t('paidVia')} ${_methodLabel(pay)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E9E52))),
                      ]
                    : [
                        Text(_statusLabel(b),
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    cancelled ? Colors.red : p.textSecondary)),
                      ],
              ),
            ),
            if (pay != null || b.status == 'COMPLETED')
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/booking-receipt', arguments: b.id),
                icon: const Icon(Icons.description_outlined, size: 15),
                label: Text(AppStrings.t('viewInvoice')),
                style: _smallButton(p),
              )
            else if (b.isOpen)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/booking-tracking', arguments: b.id),
                icon: const Icon(Icons.near_me_outlined, size: 15),
                label: Text(AppStrings.t('trackWord')),
                style: _smallButton(p),
              ),
          ]),
        ),
      ]),
    );
  }

  ButtonStyle _smallButton(AppPalette p) => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        backgroundColor: p.surface,
        side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}
