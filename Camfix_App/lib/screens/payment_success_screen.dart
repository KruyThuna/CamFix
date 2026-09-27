import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../theme/app_theme.dart';

/// Payment Successful (mockup): confirmation + a receipt the customer can
/// review, then back to the dashboard.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.payment});

  final Payment payment;

  String get _methodLabel {
    switch (payment.paymentMethod) {
      case 'APPLE_PAY':
        return AppStrings.t('applePay');
      case 'KHQR':
        return AppStrings.t('khqrTitle');
      case 'PAYPAL':
        return AppStrings.t('paypalWallet');
      case 'CARD':
        return 'Card •••• ${payment.cardLast4 ?? ''}';
      default:
        return payment.paymentMethod;
    }
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '';
    const months = [
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
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year} · '
        '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppLayout.pageGutter),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 52),
                  ),
                  const SizedBox(height: 24),
                  Text(AppStrings.t('paymentSuccessfulTitle'),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary)),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.t('paymentSuccessfulBody'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      children: [
                        _row(p, AppStrings.t('serviceId'),
                            '#${payment.serviceRef}'),
                        _row(p, AppStrings.t('amountPaid'),
                            '\$${payment.totalAmount.toStringAsFixed(2)}',
                            valueColor: AppColors.primaryBlue),
                        _row(p, AppStrings.t('dateTime'),
                            _dateLabel(payment.createdAt)),
                        _row(p, AppStrings.t('paymentMethodLabel'),
                            _methodLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                          '/booking-receipt',
                          arguments: payment.jobId),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(AppStrings.t('viewReceipt'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/dashboard', (r) => false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: p.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(AppStrings.t('returnToHome'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(AppPalette p, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: p.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? p.textPrimary)),
        ],
      ),
    );
  }
}
