import 'dart:async';
import 'dart:io' show Directory, File, Platform;
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
import 'payment_success_screen.dart';

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
    final (bankName, bankActionKey) = _getBankDetails(_selectedTab);

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
              // Top NBC standard header row
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
                                fontSize: 14.5,
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

              // KHQR Stand Ticket wrapped in RepaintBoundary for high-res image saving
              RepaintBoundary(
                key: _standTicketKey,
                child: _buildKhqrStand(p, amountToDisplay),
              ),
              const SizedBox(height: 16),

              // Action buttons: [ 📥 រក្សាទុក QR ] [ 🚀 បើកកម្មវិធីធនាគារ ]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveQrToGallery,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        AppStrings.t('saveQrToGallery'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                    child: ElevatedButton.icon(
                      onPressed: () => _openBankApp(_selectedTab),
                      icon: Icon(
                        _selectedTab == BankTab.aba
                            ? Icons.account_balance_rounded
                            : (_selectedTab == BankTab.acleda
                                ? Icons.account_balance_wallet_rounded
                                : Icons.hub_rounded),
                        size: 18,
                      ),
                      label: Text(
                        AppStrings.t(bankActionKey),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _selectedTab == BankTab.aba
                            ? const Color(0xFF005A9C)
                            : (_selectedTab == BankTab.acleda
                                ? const Color(0xFF0A2B4E)
                                : AppColors.primaryBlue),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Step-by-step guidance card for real mobile device payment
              _buildGuideCard(p),
              const SizedBox(height: 14),

              // Auto-verifying status bar
              _buildStatusBar(p),
              const SizedBox(height: 12),

              // Manual confirmation button if already paid in bank app
              OutlinedButton.icon(
                onPressed: _manualConfirmPaid,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  AppStrings.t('iHavePaid'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        color: const Color(0xFFE2E8F0),
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
            color: active ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
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

  /// Step-by-step guidance card for real mobile payments
  Widget _buildGuideCard(AppPalette p) {
    final guideText = switch (_selectedTab) {
      BankTab.aba => AppStrings.t('howToPayAba'),
      BankTab.acleda => AppStrings.t('howToPayAcleda'),
      BankTab.bakong => AppStrings.t('howToPayBakong'),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smartphone_rounded,
                  size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                AppStrings.t('howToPayMobile'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            guideText,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Colors.grey.shade700,
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
