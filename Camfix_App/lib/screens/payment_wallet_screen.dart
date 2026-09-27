import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/saved_card_store.dart';
import '../theme/app_theme.dart';
import 'add_card_screen.dart';

/// Payment & Wallet (mockup): the customer's bound payment methods - Cash
/// (always available, no setup) and their saved card, if any - plus a link
/// to add a new card. This is the settings/management screen reached from
/// Profile; the per-booking payment-method PICKER is [PaymentMethodScreen],
/// a separate screen.
class PaymentWalletScreen extends StatefulWidget {
  const PaymentWalletScreen({super.key});

  @override
  State<PaymentWalletScreen> createState() => _PaymentWalletScreenState();
}

class _PaymentWalletScreenState extends State<PaymentWalletScreen> {
  Future<void> _addCard() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddCardScreen()));
    if (mounted) setState(() {});
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
        title: Text(AppStrings.t('paymentWallet'),
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
                Text(AppStrings.t('assetsBound'),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                        color: p.textSecondary)),
                const SizedBox(height: 10),
                _methodTile(
                  p,
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF2ECC71),
                  title: AppStrings.t('cash'),
                  subtitle: AppStrings.t('cashSubtitle'),
                  trailing: _defaultChip(p),
                ),
                const SizedBox(height: 10),
                if (card != null)
                  _methodTile(
                    p,
                    icon: Icons.credit_card_rounded,
                    iconColor: AppColors.primaryBlue,
                    title: '${AppStrings.t('cardEndingIn')} ${card.last4}',
                    subtitle: '${AppStrings.t('expires')} ${card.expiry}',
                    onTap: _addCard,
                    trailing: _defaultChip(p),
                  )
                else
                  _methodTile(
                    p,
                    icon: Icons.credit_card_outlined,
                    iconColor: p.textSecondary,
                    title: AppStrings.t('noPaymentMethodYet'),
                    subtitle: AppStrings.t('addCardHint'),
                    onTap: _addCard,
                    trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                  ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _addCard,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 10),
                        Text(AppStrings.t('addNewCardLink'),
                            style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _addCard,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(AppStrings.t('addCreditDebitCard'),
                              style: TextStyle(
                                  fontSize: 13, color: p.textSecondary)),
                        ),
                        const Icon(Icons.credit_card,
                            size: 18, color: Color(0xFF1A1F71)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 26,
                          height: 16,
                          child: Stack(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFEB001B),
                                    shape: BoxShape.circle),
                              ),
                              Positioned(
                                left: 10,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF79E1B)
                                          .withValues(alpha: 0.85),
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: p.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: p.textSecondary),
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
        ),
      ),
    );
  }

  Widget _defaultChip(AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(AppStrings.t('defaultLabel'),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E9E52))),
    );
  }

  Widget _methodTile(
    AppPalette p, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
