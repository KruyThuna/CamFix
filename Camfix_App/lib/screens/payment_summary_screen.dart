import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/service_quote.dart';
import '../services/bookings_store.dart' show Booking;
import '../services/saved_card_store.dart';
import '../theme/app_theme.dart';
import 'add_card_screen.dart';
import 'payment_method_screen.dart';
import 'services_screen.dart' show categoryLabel;

/// Cost breakdown for one accepted quote - the same platform-fee/tax formula
/// as the backend (`BookingService#payQuote`), computed client-side so this
/// screen can show the total before the payment call is actually made.
class PaymentBreakdown {
  const PaymentBreakdown({
    required this.serviceFee,
    required this.partsAndLabor,
    required this.platformFee,
    required this.tax,
    required this.total,
  });

  final double serviceFee;
  final double partsAndLabor;
  final double platformFee;
  final double tax;
  final double total;

  factory PaymentBreakdown.fromQuote(ServiceQuote q) {
    final serviceFee = q.inspectionFee + q.travelFee;
    final partsAndLabor = q.laborCost + q.partsCost;
    final subtotal = serviceFee + partsAndLabor;
    final platformFee =
        _round2(subtotal * 0.018 < 0.99 ? 0.99 : subtotal * 0.018);
    final tax = _round2((subtotal + platformFee) * 0.085);
    final total = _round2(subtotal + platformFee + tax);
    return PaymentBreakdown(
      serviceFee: _round2(serviceFee),
      partsAndLabor: _round2(partsAndLabor),
      platformFee: platformFee,
      tax: tax,
      total: total,
    );
  }

  static double _round2(double v) => (v * 100).round() / 100;
}

/// Payment Summary (mockup): the cost breakdown for a just-accepted quote,
/// with a "Pay" button that goes on to choose a payment method.
class PaymentSummaryScreen extends StatefulWidget {
  const PaymentSummaryScreen(
      {super.key, required this.booking, required this.quote});

  final Booking booking;
  final ServiceQuote quote;

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(code.isEmpty
            ? AppStrings.t('promoCodeEmpty')
            : AppStrings.t('promoCodeNoneAvailable')),
      ));
  }

  Future<void> _editCard() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddCardScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final booking = widget.booking;
    final quote = widget.quote;
    final b = PaymentBreakdown.fromQuote(quote);
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(AppStrings.t('paymentSummaryTitle'),
            style: TextStyle(color: p.textPrimary)),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppLayout.pageGutter),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_repair_service_rounded,
                            color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(categoryLabel(booking.category),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: p.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              booking.technicianName ?? '',
                              style: TextStyle(
                                  fontSize: 12.5, color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.t('costBreakdown'),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.4,
                        color: p.textSecondary)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      _row(p, AppStrings.t('baseServiceFee'), b.serviceFee),
                      _row(p, AppStrings.t('standardPartsLabor'),
                          b.partsAndLabor),
                      _row(
                          p, AppStrings.t('platformProcessing'), b.platformFee),
                      _row(p, AppStrings.t('taxes85'), b.tax),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: p.border, height: 1),
                      ),
                      _row(p, AppStrings.t('totalAmount'), b.total, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        child: TextField(
                          controller: _promoController,
                          style: TextStyle(fontSize: 14, color: p.textPrimary),
                          decoration: InputDecoration(
                            icon: Icon(Icons.local_offer_outlined,
                                size: 18, color: p.textSecondary),
                            hintText: AppStrings.t('promoCodeHint'),
                            hintStyle: TextStyle(color: p.textSecondary),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _applyPromo,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(AppStrings.t('apply'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded,
                          color: AppColors.primaryBlue, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SavedCardStore.instance.hasCard
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppStrings.t('cardEndingIn')} ${SavedCardStore.instance.card!.last4}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary),
                                  ),
                                  Text(
                                    '${AppStrings.t('expiryDate')} ${SavedCardStore.instance.card!.expiry}',
                                    style: TextStyle(
                                        fontSize: 12, color: p.textSecondary),
                                  ),
                                ],
                              )
                            : Text(AppStrings.t('noPaymentMethodYet'),
                                style: TextStyle(color: p.textSecondary)),
                      ),
                      TextButton(
                        onPressed: _editCard,
                        child: Text(
                          SavedCardStore.instance.hasCard
                              ? AppStrings.t('editCard')
                              : AppStrings.t('addCard'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: p.textSecondary),
                    const SizedBox(width: 6),
                    Text(AppStrings.t('paymentsSecureNote'),
                        style:
                            TextStyle(fontSize: 11.5, color: p.textSecondary)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentMethodScreen(
                          booking: booking,
                          quote: quote,
                          breakdown: b,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      '${AppStrings.t('pay')} \$${b.total.toStringAsFixed(2)}  →',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(AppPalette p, String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 15 : 13.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: bold ? p.textPrimary : p.textSecondary)),
          Text('\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: bold ? 17 : 14,
                  fontWeight: FontWeight.w800,
                  color: bold ? AppColors.primaryBlue : p.textPrimary)),
        ],
      ),
    );
  }
}
