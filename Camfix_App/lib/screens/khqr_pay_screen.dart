import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/service_quote.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart' show Booking, BookingsStore;
import '../theme/app_theme.dart';
import 'payment_success_screen.dart';

/// Real Bakong KHQR payment: the backend builds a dynamic KHQR for the
/// quote's exact total and asks Bakong (by the QR's MD5) whether the
/// transfer has landed. Any Bakong member app (ABA, ACLEDA, Wing, ...) can
/// scan it. Polls every few seconds; on PAID the backend records the payment.
class KhqrPayScreen extends StatefulWidget {
  const KhqrPayScreen({super.key, required this.booking, required this.quote});

  final Booking booking;
  final ServiceQuote quote;

  @override
  State<KhqrPayScreen> createState() => _KhqrPayScreenState();
}

class _KhqrPayScreenState extends State<KhqrPayScreen> {
  static const _khqrRed = Color(0xFFE1232E);

  String? _qr;
  String? _md5;
  double? _amount;
  String _merchant = 'CAMFIX';
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
        _amount = (j['amount'] as num?)?.toDouble();
        _merchant = (j['merchantName'] ?? 'CAMFIX').toString();
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
      // Transient - try again on the next tick.
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

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
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
            padding: const EdgeInsets.all(20),
            children: [
              Row(children: [
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
                          letterSpacing: 1)),
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
                        Text(AppStrings.t('khqrBanksHint'),
                            style: TextStyle(
                                fontSize: 11.5, color: p.textSecondary)),
                      ]),
                ),
              ]),
              const SizedBox(height: 18),
              _qrCard(p),
              const SizedBox(height: 16),
              _statusBar(p),
              if (_qr != null && _status == 'PENDING') ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _qr!));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.t('khqrCopied'))));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: Text(AppStrings.t('copyKhqr')),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// White ticket with the red KHQR header, like the official artwork.
  Widget _qrCard(AppPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          height: 46,
          color: _khqrRed,
          alignment: Alignment.center,
          child: const Text('KHQR',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(children: [
            Text(_merchant,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(_amount == null ? '—' : '\$${_amount!.toStringAsFixed(2)} USD',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            const Divider(height: 22),
            SizedBox(
              width: 230,
              height: 230,
              child: switch (_status) {
                'LOADING' => const Center(child: CircularProgressIndicator()),
                'ERROR' => Center(
                    child: Text(_error ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red))),
                _ => Stack(alignment: Alignment.center, children: [
                    Opacity(
                      opacity: _status == 'EXPIRED' ? 0.15 : 1,
                      child: QrImageView(
                        data: _qr ?? '',
                        size: 230,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    if (_status == 'EXPIRED')
                      FilledButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(AppStrings.t('newQr')),
                      ),
                  ]),
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statusBar(AppPalette p) {
    final expired = _status == 'EXPIRED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (expired ? Colors.red : AppColors.primaryBlue)
            .withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        if (_status == 'PENDING')
          const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(expired ? Icons.timer_off_rounded : Icons.info_outline,
              size: 16, color: expired ? Colors.red : AppColors.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(AppStrings.t(expired ? 'khqrExpired' : 'khqrWaiting'),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: expired ? Colors.red : AppColors.primaryBlue)),
        ),
        if (_status == 'PENDING')
          Text(_countdown,
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue)),
      ]),
    );
  }
}
