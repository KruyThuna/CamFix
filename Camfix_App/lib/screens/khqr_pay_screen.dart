import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/service_quote.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart' show Booking, BookingsStore;
import '../theme/app_theme.dart';
import 'payment_success_screen.dart';

enum BankTab { bakong, aba, acleda }

/// Real Bakong KHQR payment: dynamic KHQR for the accepted quote.
/// Supports NBC Bakong KHQR, ABA Mobile, and ACLEDA Pay with auto-verification.
class KhqrPayScreen extends StatefulWidget {
  const KhqrPayScreen({super.key, required this.booking, required this.quote});

  final Booking booking;
  final ServiceQuote quote;

  @override
  State<KhqrPayScreen> createState() => _KhqrPayScreenState();
}

class _KhqrPayScreenState extends State<KhqrPayScreen> {
  static const _khqrRed = Color(0xFFE1232E);

  BankTab _selectedTab = BankTab.bakong;
  String? _qr;
  String? _md5;
  double? _amount;
  String _merchant = 'CamFix Field Service Co., Ltd.';
  DateTime? _expiresAt;
  String _status = 'LOADING'; // LOADING | PENDING | EXPIRED | ERROR
  String? _error;
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _poll?.cancel();
    _tick?.cancel();
    setState(() {
      _status = 'LOADING';
      _error = null;
    });
    try {
      final j = await BookingsApi.instance
          .startKhqr(widget.booking.id, widget.quote.id);
      if (!mounted) return;
      setState(() {
        _qr = j['qrString']?.toString();
        _md5 = j['md5']?.toString();
        _amount = (j['amount'] as num?)?.toDouble() ?? widget.quote.totalAmount;
        _merchant = (j['merchantName'] ?? 'CamFix Field Service Co., Ltd.').toString();
        _expiresAt = DateTime.tryParse((j['expiresAt'] ?? '').toString());
        _status = 'PENDING';
      });
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_remaining == Duration.zero) _check();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'ERROR';
          _error = e.toString();
        });
      }
    }
  }

  Duration get _remaining {
    final e = _expiresAt;
    if (e == null) return Duration.zero;
    final d = e.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  bool _checking = false;

  Future<void> _check() async {
    final md5 = _md5;
    if (md5 == null || _checking || _status != 'PENDING') return;
    _checking = true;
    try {
      final j = await BookingsApi.instance.khqrStatus(widget.booking.id, md5);
      if (!mounted) return;
      final status = (j['status'] ?? 'PENDING').toString();
      if (status == 'PAID' && j['payment'] is Map<String, dynamic>) {
        _poll?.cancel();
        _tick?.cancel();
        unawaited(BookingsStore.instance.refresh());
        final payment = Payment.fromJson(j['payment'] as Map<String, dynamic>);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(payment: payment)));
      } else if (status == 'EXPIRED') {
        _poll?.cancel();
        _tick?.cancel();
        setState(() => _status = 'EXPIRED');
      }
    } catch (_) {
      // Transient - retry on next poll
    } finally {
      _checking = false;
    }
  }

  String get _countdown {
    final r = _remaining;
    final m = r.inMinutes.toString().padLeft(2, '0');
    final s = (r.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _downloadQr() async {
    if (_qr == null) return;
    await Clipboard.setData(ClipboardData(text: _qr!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.t('khqrCopied'))),
    );
  }

  Future<void> _openBankingOrPayWay() async {
    final method = switch (_selectedTab) {
      BankTab.aba => 'ABA',
      BankTab.acleda => 'ACLEDA',
      BankTab.bakong => 'KHQR',
    };

    // Deep link scheme to launch the bank app if installed
    if (_selectedTab == BankTab.aba) {
      final abaUri = Uri.parse('aba://qr?data=${Uri.encodeComponent(_qr ?? '')}');
      if (await canLaunchUrl(abaUri)) {
        await launchUrl(abaUri, mode: LaunchMode.externalApplication);
      }
    } else if (_selectedTab == BankTab.acleda) {
      final acledaUri = Uri.parse('acleda://qr?data=${Uri.encodeComponent(_qr ?? '')}');
      if (await canLaunchUrl(acledaUri)) {
        await launchUrl(acledaUri, mode: LaunchMode.externalApplication);
      }
    } else if (_selectedTab == BankTab.bakong) {
      final bakongUri = Uri.parse('bakong://qr?data=${Uri.encodeComponent(_qr ?? '')}');
      if (await canLaunchUrl(bakongUri)) {
        await launchUrl(bakongUri, mode: LaunchMode.externalApplication);
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('paywayLink')),
        content: Text(AppStrings.t('confirmPaymentPrompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.t('confirmPaid')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _status = 'LOADING');
        final payment = await BookingsApi.instance.payQuote(
          widget.booking.id,
          widget.quote.id,
          paymentMethod: method,
        );
        _poll?.cancel();
        _tick?.cancel();
        unawaited(BookingsStore.instance.refresh());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(payment: payment)),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _status = 'PENDING';
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final amountToDisplay = _amount ?? widget.quote.totalAmount;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(AppStrings.t('khqrTitle'),
            style: TextStyle(color: p.textPrimary)),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Title & Direct Pay banner
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _khqrRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('KHQR',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t('scanWithBanking'),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: p.textPrimary)),
                        Text('NBC Bakong Standard • Instant Settlement',
                            style: TextStyle(
                                fontSize: 11, color: p.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _khqrRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(AppStrings.t('directPay'),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bank tab switcher: [Bakong KHQR] [ABA Mobile] [ACLEDA Pay]
              _buildBankTabs(),
              const SizedBox(height: 16),

              // KHQR Stand Ticket
              _buildKhqrStand(p, amountToDisplay),
              const SizedBox(height: 16),

              // Action buttons: [ Download QR ] [ PayWay - Payment Link ]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadQr,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(AppStrings.t('downloadQr'),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                        backgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.05),
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openBankingOrPayWay,
                      icon: const Icon(Icons.credit_card_rounded, size: 18),
                      label: Text(AppStrings.t('paywayLink'),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                        backgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.05),
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Auto-verifying status bar
              _buildStatusBar(p),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _tabPill(BankTab.bakong, AppStrings.t('bakongKhqrTab')),
          _tabPill(BankTab.aba, AppStrings.t('abaMobileTab')),
          _tabPill(BankTab.acleda, AppStrings.t('acledaPayTab')),
        ],
      ),
    );
  }

  Widget _tabPill(BankTab tab, String label) {
    final active = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Official Red KHQR Stand design
  Widget _buildKhqrStand(AppPalette p, double amount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _khqrRed.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Bakong Emblem & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: _khqrRed, width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.hub_rounded, size: 18, color: _khqrRed),
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'បាគង',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _khqrRed,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'BAKONG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _khqrRed,
                      letterSpacing: 1.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t('scanPayDone'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // Center QR Code with red circular emblem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SizedBox(
              width: 210,
              height: 210,
              child: switch (_status) {
                'LOADING' => const Center(child: CircularProgressIndicator()),
                'ERROR' => Center(
                    child: Text(_error ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 12))),
                _ => Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _status == 'EXPIRED' ? 0.15 : 1,
                        child: QrImageView(
                          data: _qr ?? 'CAMFIX-KHQR-DEV',
                          size: 210,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                      // Center Red Bakong emblem
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _khqrRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (_status == 'EXPIRED')
                        FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(AppStrings.t('newQr')),
                        ),
                    ],
                  ),
              },
            ),
          ),
          const SizedBox(height: 12),

          // Merchant name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _merchant,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Amount
          Text(
            '\$${amount.toStringAsFixed(2)} USD',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),

          // Red curved ribbon at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: _khqrRed,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  AppStrings.t('memberOfKhqr'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(AppPalette p) {
    final expired = _status == 'EXPIRED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (_status == 'PENDING')
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.45),
                    blurRadius: 4,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
            )
          else
            Icon(expired ? Icons.timer_off_rounded : Icons.info_outline,
                size: 16, color: expired ? Colors.red : AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              expired
                  ? AppStrings.t('khqrExpired')
                  : AppStrings.t('autoVerifying'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: expired ? Colors.red : const Color(0xFF1E40AF),
              ),
            ),
          ),
          if (_status == 'PENDING')
            Text(
              _countdown,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.primaryBlue,
              ),
            ),
        ],
      ),
    );
  }
}
