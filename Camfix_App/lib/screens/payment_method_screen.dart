import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/service_quote.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart' show Booking;
import '../services/saved_card_store.dart';
import '../theme/app_theme.dart';
import 'add_card_screen.dart';
import 'khqr_pay_screen.dart';
import 'payment_success_screen.dart';
import 'payment_summary_screen.dart';

enum _Method { khqr, applePay, card, paypal }

/// Payment Method (mockup): choose how to pay, then confirm. Card needs a
/// saved card on file first - if there isn't one, "Confirm Payment" opens
/// Add New Card instead of charging.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({
    super.key,
    required this.booking,
    required this.quote,
    required this.breakdown,
  });

  final Booking booking;
  final ServiceQuote quote;
  final PaymentBreakdown breakdown;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  _Method _selected = _Method.applePay;
  bool _busy = false;

  /// Real Bakong KHQR - only offered when the server has merchant keys.
  bool _khqr = false;

  @override
  void initState() {
    super.initState();
    BookingsApi.instance.khqrEnabled().then((on) {
      if (!mounted || !on) return;
      setState(() {
        _khqr = true;
        _selected = _Method.khqr;
      });
    });
  }

  Future<void> _confirm() async {
    if (_selected == _Method.khqr) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            KhqrPayScreen(booking: widget.booking, quote: widget.quote),
      ));
      return;
    }
    if (_selected == _Method.card && !SavedCardStore.instance.hasCard) {
      final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AddCardScreen()),
      );
      if (added != true || !mounted) return;
      setState(() {}); // re-read SavedCardStore.instance.card below
    }
    setState(() => _busy = true);
    try {
      final payment = await BookingsApi.instance.payQuote(
        widget.booking.id,
        widget.quote.id,
        paymentMethod: switch (_selected) {
          _Method.applePay => 'APPLE_PAY',
          _Method.card => 'CARD',
          _Method.paypal => 'PAYPAL',
          _Method.khqr => 'KHQR',
        },
        cardLast4: _selected == _Method.card
            ? SavedCardStore.instance.card?.last4
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(payment: payment)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final card = SavedCardStore.instance.card;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(AppStrings.t('paymentMethodTitle'),
            style: TextStyle(color: p.textPrimary)),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
            child: Column(
              children: [
                Expanded(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.t('totalAmount'),
                                style: TextStyle(color: p.textSecondary)),
                            Text(
                                '\$${widget.breakdown.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.primaryBlue)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(AppStrings.t('choosePaymentMethod'),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.4,
                              color: p.textSecondary)),
                      const SizedBox(height: 4),
                      Text(AppStrings.t('choosePaymentMethodHint'),
                          style: TextStyle(
                              fontSize: 12.5, color: p.textSecondary)),
                      const SizedBox(height: 12),
                      if (_khqr) ...[
                        _methodTile(
                          p,
                          method: _Method.khqr,
                          icon: Icons.qr_code_2_rounded,
                          title: AppStrings.t('khqrTitle'),
                          subtitle: AppStrings.t('khqrSubtitle'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _methodTile(
                        p,
                        method: _Method.applePay,
                        icon: Icons.apple,
                        title: AppStrings.t('applePay'),
                        subtitle: AppStrings.t('applePaySubtitle'),
                      ),
                      const SizedBox(height: 10),
                      _methodTile(
                        p,
                        method: _Method.card,
                        icon: Icons.credit_card_rounded,
                        title: AppStrings.t('creditDebitCard'),
                        subtitle: card != null
                            ? '${AppStrings.t('cardEndingIn')} ${card.last4}'
                            : AppStrings.t('creditDebitCardSubtitle'),
                      ),
                      const SizedBox(height: 10),
                      _methodTile(
                        p,
                        method: _Method.paypal,
                        icon: Icons.account_balance_wallet_outlined,
                        title: AppStrings.t('paypalWallet'),
                        subtitle: AppStrings.t('paypalWalletSubtitle'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 14, color: p.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(AppStrings.t('paymentsSecureNote'),
                                style: TextStyle(
                                    fontSize: 11.5, color: p.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppLayout.pageGutter, 0, AppLayout.pageGutter, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppStrings.t('totalAmount'),
                              style: TextStyle(color: p.textSecondary)),
                          Text('\$${widget.breakdown.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  '${AppStrings.t('confirmPayment')}  →',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodTile(
    AppPalette p, {
    required _Method method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selected == method;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selected = method),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primaryBlue : p.border,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryBlue : p.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
