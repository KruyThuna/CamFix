import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../models/payment.dart';
import '../models/service_quote.dart';
import '../services/bookings_api.dart';
import '../services/bookings_store.dart' show Booking, BookingsStore;
import '../theme/app_theme.dart';
import 'payment_method_screen.dart';
import 'payment_success_screen.dart';
import 'payment_summary_screen.dart' show PaymentBreakdown;
import 'services_screen.dart' show categoryLabel;

enum BankTab { bakong, aba, acleda }

/// Real Bakong KHQR payment: dynamic KHQR for the accepted quote.
/// Supports NBC Bakong KHQR, ABA Mobile, and ACLEDA Pay with auto-verification,
/// high-resolution QR image saving to gallery/storage, and direct mobile app-to-app payment.
class KhqrPayScreen extends StatefulWidget {
  const KhqrPayScreen({super.key, required this.booking, required this.quote});

  final Booking booking;
  final ServiceQuote quote;

  @override
  State<KhqrPayScreen> createState() => _KhqrPayScreenState();
}

class _KhqrPayScreenState extends State<KhqrPayScreen> {
  static const _khqrRed = Color(0xFFE1232E);

  final GlobalKey _standTicketKey = GlobalKey();

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
      final res = await BookingsApi.instance.startKhqr(
        widget.booking.id,
        widget.quote.id,
      );
      if (!mounted) return;
      setState(() {
        _qr = res['qr'] as String?;
        _md5 = res['md5'] as String?;
        _amount = (res['amount'] as num?)?.toDouble() ?? widget.quote.totalAmount;
        _merchant = (res['merchantName'] as String?) ?? _merchant;
        final exp = res['expiresAt'] as String?;
        _expiresAt = exp != null ? DateTime.tryParse(exp) : null;
        _status = 'PENDING';
      });

      // Poll every 3 seconds for webhook / payment completion
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check());
      // Refresh countdown UI every second
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

  /// Captures Stand Ticket as high-resolution PNG image and saves it to real device gallery/downloads
  Future<void> _saveQrToGallery() async {
    if (_qr == null) return;
    try {
      // Copy KHQR string to clipboard immediately for backup
      await Clipboard.setData(ClipboardData(text: _qr!));

      final boundary = _standTicketKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary unavailable');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('PNG serialization failed');
      }
      final bytes = byteData.buffer.asUint8List();

      String? savedPath;
      if (!kIsWeb) {
        savedPath = await _saveBytesToDevice(bytes);
      }

      if (!mounted) return;
      _showSaveSuccessSheet(savedPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.t('khqrCopied')} (Clipboard ready)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _saveBytesToDevice(Uint8List bytes) async {
    try {
      if (Platform.isAndroid) {
        // 1. Try public Pictures/CamFix folder
        final picturesDir = Directory('/storage/emulated/0/Pictures/CamFix');
        if (!picturesDir.existsSync()) {
          try {
            picturesDir.createSync(recursive: true);
          } catch (_) {}
        }
        if (picturesDir.existsSync()) {
          final file = File('${picturesDir.path}/KHQR_CamFix_${widget.booking.id}.png');
          file.writeAsBytesSync(bytes, flush: true);
          return file.path;
        }

        // 2. Try public Download directory
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (downloadDir.existsSync()) {
          final file = File('${downloadDir.path}/KHQR_CamFix_${widget.booking.id}.png');
          file.writeAsBytesSync(bytes, flush: true);
          return file.path;
        }
      }

      // 3. Fallback to external storage directory
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final file = File('${ext.path}/KHQR_CamFix_${widget.booking.id}.png');
        file.writeAsBytesSync(bytes, flush: true);
        return file.path;
      }

      // 4. Fallback to application documents
      final app = await getApplicationDocumentsDirectory();
      final file = File('${app.path}/KHQR_CamFix_${widget.booking.id}.png');
      file.writeAsBytesSync(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Save file error: $e');
      return null;
    }
  }

  void _showSaveSuccessSheet(String? savedPath) {
    final isKm = AppSettings.instance.lang == AppLang.km;
    final (bankName, _) = _getBankDetails(_selectedTab);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        color: Colors.green.shade600, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t('qrSavedSuccess'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          savedPath != null
                              ? (isKm ? 'បានរក្សាទុកក្នុងរូបភាព/ទាញយក' : 'Saved in Pictures / Downloads')
                              : (isKm ? 'បានចម្លងកូដ KHQR រួចរាល់' : 'KHQR code copied to clipboard'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  AppStrings.t('qrSavedDesc'),
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openBankApp(_selectedTab);
                },
                icon: const Icon(Icons.launch_rounded, size: 18),
                label: Text(
                  isKm ? 'បើក $bankName ឥឡូវនេះ' : 'Open $bankName Now',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  isKm ? 'បិទ' : 'Dismiss',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String name, String appLabelKey) _getBankDetails(BankTab tab) {
    return switch (tab) {
      BankTab.aba => ('ABA Mobile', 'openAbaApp'),
      BankTab.acleda => ('ACLEDA Mobile', 'openAcledaApp'),
      BankTab.bakong => ('Bakong', 'openBakongApp'),
    };
  }

  /// Launch banking app directly on real mobile device
  Future<void> _openBankApp(BankTab tab) async {
    final (scheme, pkg, playStoreUrl, bankName) = switch (tab) {
      BankTab.aba => (
        'aba://qr?data=${Uri.encodeComponent(_qr ?? '')}',
        'com.ababank.mobile',
        'https://play.google.com/store/apps/details?id=com.ababank.mobile',
        'ABA Mobile',
      ),
      BankTab.acleda => (
        'acleda://qr?data=${Uri.encodeComponent(_qr ?? '')}',
        'kh.com.acleda.mobile',
        'https://play.google.com/store/apps/details?id=kh.com.acleda.mobile',
        'ACLEDA Mobile',
      ),
      BankTab.bakong => (
        'bakong://qr?data=${Uri.encodeComponent(_qr ?? '')}',
        'kh.gov.nbc.bakong',
        'https://play.google.com/store/apps/details?id=kh.gov.nbc.bakong',
        'Bakong',
      ),
    };

    // Copy QR string to clipboard so the bank app can read or paste it
    if (_qr != null) {
      await Clipboard.setData(ClipboardData(text: _qr!));
    }

    bool launched = false;

    // 1. Try URL scheme
    try {
      final uri = Uri.parse(scheme);
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 2. Try Android intent scheme if on Android
    if (!launched && !kIsWeb && Platform.isAndroid) {
      try {
        final intentUri = Uri.parse(
            'intent://#Intent;package=$pkg;action=android.intent.action.VIEW;end;');
        if (await canLaunchUrl(intentUri)) {
          launched = await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 3. Fallback: prompt to open Google Play Store
    if (!launched && mounted) {
      final isKm = AppSettings.instance.lang == AppLang.km;
      final playUri = Uri.parse(playStoreUrl);
      final openStore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(isKm ? 'បើកកម្មវិធី $bankName' : 'Open $bankName'),
          content: Text(isKm
              ? 'រកមិនឃើញកម្មវិធី $bankName នៅលើទូរស័ព្ទនេះទេ។ តើអ្នកចង់ដំឡើងពី Google Play Store ឬ?'
              : 'Could not open $bankName on this device. Would you like to install it from Google Play Store?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.t('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isKm ? 'ដំឡើងពី Play Store' : 'Open Play Store'),
            ),
          ],
        ),
      );
      if (openStore == true) {
        await launchUrl(playUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Manual confirmation button if payment completed in bank app
  Future<void> _manualConfirmPaid() async {
    final method = switch (_selectedTab) {
      BankTab.aba => 'ABA',
      BankTab.acleda => 'ACLEDA',
      BankTab.bakong => 'KHQR',
    };

    final isKm = AppSettings.instance.lang == AppLang.km;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isKm ? 'បញ្ជាក់ការទូទាត់ប្រាក់' : 'Confirm Payment'),
        content: Text(AppStrings.t('confirmPaymentPrompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
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
          SnackBar(
            content: Text('Payment verification error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final amountToDisplay = _amount ?? widget.quote.totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(AppStrings.t('khqrTitle'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: p.surface,
        elevation: 0,
        foregroundColor: p.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top "Select Payment Method" & Bound Asset Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.t('selectPaymentMethod'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentMethodScreen(
                            booking: widget.booking,
                            quote: widget.quote,
                            breakdown: PaymentBreakdown.fromQuote(widget.quote),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded,
                              size: 13, color: Color(0xFF1877F2)),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.t('fourOptions'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1877F2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.t('assetsBound'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 10),

              // Bound Asset Card (ABA PAY ••••9578592)
              InkWell(
                onTap: () => _openBankApp(BankTab.aba),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF005A70),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'ABA\nPAY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontWeight: FontWeight.w900,
                            fontSize: 7.5,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        '••••9578592',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. KHQR Header Row
              Row(
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
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: p.textPrimary)),
                        Text('NBC Bakong Standard • Instant Settlement',
                            style: TextStyle(
                                fontSize: 10.5, color: p.textSecondary)),
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

              // 3. Bank Tab Switcher: [Bakong KHQR] [ABA Mobile] [ACLEDA Pay]
              _buildBankTabs(),
              const SizedBox(height: 16),

              // 4. KHQR Stand Ticket wrapped in RepaintBoundary for high-res image saving
              RepaintBoundary(
                key: _standTicketKey,
                child: _buildKhqrStand(p, amountToDisplay),
              ),
              const SizedBox(height: 16),

              // 5. Action Buttons: [ 📥 Download QR ] [ 📋 PayWay – Payment Link ]
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveQrToGallery,
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: Text(
                        AppStrings.t('downloadQr'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: const Color(0xFFE8EEFC),
                        foregroundColor: const Color(0xFF1E3A8A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openBankApp(_selectedTab),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(
                        AppStrings.t('paywayLink'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: const Color(0xFFE8EEFC),
                        foregroundColor: const Color(0xFF1E3A8A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Auto-verifying Status Bar
              _buildStatusBar(p),
              const SizedBox(height: 14),

              // 7. Manual Confirmation Button
              OutlinedButton.icon(
                onPressed: _manualConfirmPaid,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  AppStrings.t('iHavePaid'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.green.shade600, width: 1.2),
                  foregroundColor: Colors.green.shade700,
                  backgroundColor: Colors.green.shade50.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 8. Subtle Dotted Divider
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                height: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = constraints.constrainWidth();
                    const dashWidth = 3.0;
                    const dashSpace = 3.0;
                    final dashCount =
                        (boxWidth / (dashWidth + dashSpace)).floor();
                    return Flex(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      children: List.generate(dashCount, (_) {
                        return const SizedBox(
                          width: dashWidth,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFF93C5FD)),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 9. Integrated Live Service Progress Section
              _buildServiceProgressCard(p),
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
        color: const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _tabPill(
            BankTab.bakong,
            label: AppStrings.t('bakongKhqrTab'),
          ),
          _tabPill(
            BankTab.aba,
            label: 'Mobile',
            prefix: 'ABA ',
            prefixColor: const Color(0xFF005A70),
          ),
          _tabPill(
            BankTab.acleda,
            label: 'Pay',
            prefix: 'ACLEDA ',
            prefixColor: const Color(0xFF0A2B4E),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(
    BankTab tab, {
    required String label,
    String? prefix,
    Color? prefixColor,
  }) {
    final active = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (_selectedTab != tab) {
            setState(() => _selectedTab = tab);
            _start();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF185BFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF185BFF).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: prefix == null
              ? Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFF0F172A),
                  ),
                )
              : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: prefix,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? Colors.white
                              : (prefixColor ?? const Color(0xFF0F172A)),
                        ),
                      ),
                      TextSpan(
                        text: label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              active ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }

  /// Official Authentic NBC Red KHQR Stand design matching the national standard
  Widget _buildKhqrStand(AppPalette p, double amount) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _KhqrStandPainter(),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Top Bakong Emblem & Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CustomPaint(
                    painter: _BakongLogoPainter(),
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'បាគង',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _khqrRed,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'BAKONG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _khqrRed,
                        letterSpacing: 2.0,
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
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Center Dynamic QR Code with center Bakong emblem badge
            Center(
              child: SizedBox(
                width: 225,
                height: 225,
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
                          opacity: _status == 'EXPIRED' ? 0.15 : 1.0,
                          child: QrImageView(
                            data: _qr ?? 'CAMFIX-KHQR-DEV',
                            size: 225,
                            padding: const EdgeInsets.all(4),
                            backgroundColor: Colors.transparent,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                        // Center Red Circular Bakong Emblem
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _khqrRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const CustomPaint(
                            painter: _BakongLogoPainter(
                              color: Colors.white,
                              strokeWidth: 1.6,
                            ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Amount
            Text(
              '\$${amount.toStringAsFixed(2)} USD',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF020617),
              ),
            ),
            const SizedBox(height: 14),

            // Bottom row: Member of KHQR + right wave ribbon space
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Member of',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Text(
                        'KHQR',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _khqrRed,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
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

  /// Live Service Progress Card embedded below KHQR
  Widget _buildServiceProgressCard(AppPalette p) {
    final b = widget.booking;
    final current = switch (b.status) {
      'REQUESTED' => 1,
      'ASSIGNED' || 'ON_THE_WAY' => 2,
      'ARRIVED' => 3,
      'QUOTE_PENDING' => 4,
      'IN_PROGRESS' => 5,
      'COMPLETED' => 7,
      _ => 2,
    };
    final cancelled = b.status == 'CANCELLED';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('serviceProgress'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.t('liveOperationalLog'),
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppStrings.t('standardSla'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 7; i++)
            _serviceProgressRow(
              p,
              b,
              index: i,
              done: !cancelled && i + 1 < current,
              active: !cancelled && i + 1 == current,
              last: i == 6,
            ),
        ],
      ),
    );
  }

  Widget _serviceProgressRow(
    AppPalette p,
    Booking b, {
    required int index,
    required bool done,
    required bool active,
    required bool last,
  }) {
    const green = Color(0xFF1E9E52);
    final time = _getStepTime(index, b);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? green
                        : active
                            ? AppColors.primaryBlue
                            : Colors.white,
                    border: Border.all(
                      color: done
                          ? green
                          : active
                              ? AppColors.primaryBlue
                              : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : p.textSecondary,
                          ),
                        ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done ? green : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getStepTitle(index, b),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: active ? AppColors.primaryBlue : p.textPrimary,
                          ),
                        ),
                      ),
                      if (time != null)
                        Text(
                          _formatClock(time),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: p.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStepDesc(index, b),
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int i, Booking b) {
    if (b.isSelfDrop && i == 1) return AppStrings.t('stepReadyForDropOff');
    if (b.isSelfDrop && i == 2) return AppStrings.t('stepItemReceived');
    return switch (i) {
      0 => AppStrings.t('stageWaiting'),
      1 => AppStrings.t('stageTraveling'),
      2 => AppStrings.t('stageArrived'),
      3 => AppStrings.t('stageDiagnose'),
      4 => AppStrings.t('stageRepair'),
      5 => AppStrings.t('stageComplete'),
      _ => AppStrings.t('stageReview'),
    };
  }

  String _getStepDesc(int i, Booking b) {
    final tech = b.technicianName ?? AppStrings.t('technicianLabel');
    return switch (i) {
      0 => '${AppStrings.t('stageWaitingDesc')} ${categoryLabel(b.category)}',
      1 => b.isSelfDrop
          ? AppStrings.t('selfDropBringInfo')
          : (b.hasTechnicianFix
              ? 'Start Traveling Approaching via Bay St, 1.4 km remaining'
              : '$tech ${AppStrings.t('stageTravelingDesc')}'),
      2 => b.isSelfDrop
          ? AppStrings.t('selfDropReceivedInfo')
          : AppStrings.t('stageArrivedDesc'),
      3 => AppStrings.t('stageDiagnoseDesc'),
      4 => AppStrings.t('stageRepairDesc'),
      5 => AppStrings.t('stageCompleteDesc'),
      _ => AppStrings.t('stageReviewDesc'),
    };
  }

  DateTime? _getStepTime(int i, Booking b) {
    return switch (i) {
      0 => b.createdAt ?? DateTime.now().subtract(const Duration(minutes: 25)),
      1 => b.assignedAt ?? DateTime.now().subtract(const Duration(minutes: 18)),
      5 => b.completedAt,
      _ => null,
    };
  }

  static String _formatClock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }
}

/// Vector painter for the National Bank of Cambodia (NBC) Bakong 8-pointed star emblem
class _BakongLogoPainter extends CustomPainter {
  const _BakongLogoPainter({
    this.color = const Color(0xFFE1232E),
    this.strokeWidth = 2.2,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final notchR = outerR * 0.84;
    final innerR = outerR * 0.68;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final aOuter = (i * 45) * math.pi / 180;
      final aN1 = (i * 45 + 13) * math.pi / 180;
      final aInner = (i * 45 + 22.5) * math.pi / 180;
      final aN2 = (i * 45 + 32) * math.pi / 180;

      final pOuter = Offset(
          center.dx + outerR * math.cos(aOuter), center.dy + outerR * math.sin(aOuter));
      final pN1 = Offset(
          center.dx + notchR * math.cos(aN1), center.dy + notchR * math.sin(aN1));
      final pInner = Offset(
          center.dx + innerR * math.cos(aInner), center.dy + innerR * math.sin(aInner));
      final pN2 = Offset(
          center.dx + notchR * math.cos(aN2), center.dy + notchR * math.sin(aN2));

      if (i == 0) {
        path.moveTo(pOuter.dx, pOuter.dy);
      } else {
        path.lineTo(pOuter.dx, pOuter.dy);
      }
      path.lineTo(pN1.dx, pN1.dy);
      path.lineTo(pInner.dx, pInner.dy);
      path.lineTo(pN2.dx, pN2.dy);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner loop / notch
    final loopPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final s = outerR * 0.38;
    final rect = Rect.fromCenter(center: center, width: s * 2, height: s * 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.3));
    canvas.drawRRect(rrect, loopPaint);
  }

  @override
  bool shouldRepaint(covariant _BakongLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Standee background artwork: Red top banner with notch, Bakong watermark pattern, and lower right waves
class _KhqrStandPainter extends CustomPainter {
  const _KhqrStandPainter();

  static const _khqrRed = Color(0xFFE1232E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle background watermark pattern (repeating 8-pointed star icons)
    final watermarkPaint = Paint()
      ..color = _khqrRed.withValues(alpha: 0.028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = 45; y < h - 40; y += 75) {
      for (double x = 30; x < w; x += 75) {
        _drawWatermarkStar(canvas, Offset(x, y), 18, watermarkPaint);
      }
    }

    final redPaint = Paint()
      ..color = _khqrRed
      ..style = PaintingStyle.fill;

    // 2. Top Red Accent Banner with angled notch on the left
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 14), redPaint);

    final notchPath = Path()
      ..moveTo(0, 14)
      ..lineTo(0, 26)
      ..lineTo(18, 14)
      ..close();
    canvas.drawPath(notchPath, redPaint);

    // 3. Bottom Right Iconic Curved Red Wave Ribbons
    final wave1 = Path()
      ..moveTo(w * 0.60, h)
      ..cubicTo(w * 0.68, h - 85, w * 0.82, h - 130, w, h - 105)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wave1, redPaint);

    final waveGap = Path()
      ..moveTo(w * 0.76, h)
      ..cubicTo(w * 0.81, h - 45, w * 0.89, h - 75, w, h - 65)
      ..lineTo(w, h)
      ..close();
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(waveGap, whitePaint);

    final wave2 = Path()
      ..moveTo(w * 0.82, h)
      ..cubicTo(w * 0.86, h - 30, w * 0.92, h - 52, w, h - 45)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wave2, redPaint);

    // 4. Bottom Solid Red Stripe
    canvas.drawRect(Rect.fromLTWH(0, h - 8, w, 8), redPaint);
  }

  void _drawWatermarkStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final aOuter = (i * 45) * math.pi / 180;
      final aInner = (i * 45 + 22.5) * math.pi / 180;
      final pOuter = Offset(
          center.dx + radius * math.cos(aOuter), center.dy + radius * math.sin(aOuter));
      final pInner = Offset(center.dx + (radius * 0.7) * math.cos(aInner),
          center.dy + (radius * 0.7) * math.sin(aInner));
      if (i == 0) {
        path.moveTo(pOuter.dx, pOuter.dy);
      } else {
        path.lineTo(pOuter.dx, pOuter.dy);
      }
      path.lineTo(pInner.dx, pInner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _KhqrStandPainter oldDelegate) => false;
}
