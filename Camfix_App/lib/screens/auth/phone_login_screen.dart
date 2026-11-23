import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/language.dart';
import '../../services/api_client.dart';
import '../../services/api_config.dart';
import '../../services/auth_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/otp_sent_dialog.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  static const String _dialCode = '+855';
  final _phone = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  /// National subscriber digits the user typed, with any trunk "0" dropped
  /// (people often type 097… — that leading 0 isn't part of the number).
  String get _nsn {
    var digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// E.164, e.g. "+855978068525".
  String get _e164 => '$_dialCode$_nsn';

  /// A Cambodian mobile number is 8–9 subscriber digits and not all the same.
  bool get _phoneLooksValid {
    final n = _nsn;
    return n.length >= 8 && n.length <= 9 && !RegExp(r'^(\d)\1+$').hasMatch(n);
  }

  void _snack(String msg, {bool showServerAction = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          action: showServerAction
              ? SnackBarAction(
                  label: 'Server URL',
                  textColor: AppColors.cyan,
                  onPressed: _showServerDialog,
                )
              : null,
          duration: Duration(seconds: showServerAction ? 8 : 4),
        ),
      );
  }

  void _showServerDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend server endpoint for this phone:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Quick Presets:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text(
                    'api.camonline.store',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () => controller.text = ApiConfig.domainUrl,
                ),
                ActionChip(
                  label: const Text('Live Tunnel', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = ApiConfig.liveTunnelUrl,
                ),
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:8081',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = ApiConfig.defaultProductionUrl;
            },
            child: const Text('Default'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await ApiConfig.setCustomUrl(controller.text.trim());
              nav.pop();
              if (!mounted) return;
              setState(() {});
              _snack('Server updated to: ${ApiConfig.baseUrl}');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_phoneLooksValid) {
      _snack(AppStrings.t('errEnterValidPhone'));
      return;
    }
    setState(() => _sending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _e164,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCred =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final idToken = await userCred.user?.getIdToken();
            if (idToken != null) {
              await AuthApi.instance.loginWithFirebasePhone(idToken);
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/home', (r) => false);
              }
            }
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _sending = false);
            _snack('Firebase: ${e.message ?? e.code}');
            _sendBackendOtpFallback();
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _sending = false);
          Navigator.of(context).pushNamed('/verify-code', arguments: {
            'phone': _e164,
            'verificationId': verificationId,
            'resendToken': resendToken,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (_) {
      _sendBackendOtpFallback();
    }
  }

  Future<void> _sendBackendOtpFallback() async {
    try {
      final res = await AuthApi.instance.requestPhoneOtp(_e164);
      if (!mounted) return;
      setState(() => _sending = false);
      await showOtpSentDialog(context,
          to: _e164, viaSms: true, devCode: res.devCode);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/verify-code', arguments: {
        'phone': _e164,
        'devCode': res.devCode,
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        _snack(e.message, showServerAction: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        _snack('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleBackButton(
                    onPressed: () => Navigator.of(context).pop()),
              ),
              const SizedBox(height: 28),
              Text(AppStrings.t('enterWord'), style: AppText.h1),
              Text(AppStrings.t('phoneNumbersTitle'), style: AppText.h1),
              const SizedBox(height: 28),
              Text(AppStrings.t('phoneNumber'), style: AppText.body),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Text('🇰🇭', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    const Text(_dialCode,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.hintGrey, size: 18),
                    Container(
                      height: 24,
                      width: 1,
                      color: AppColors.hintGrey.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        onSubmitted: (_) => _sending ? null : _sendOtp(),
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: AppStrings.t('phoneNumberHint'),
                          hintStyle: const TextStyle(color: AppColors.hintGrey),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.hintGrey, size: 18),
                      onPressed: () => _phone.clear(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _sending
                    ? AppStrings.t('sendingCode')
                    : AppStrings.t('continue'),
                onPressed: _sending ? null : _sendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
