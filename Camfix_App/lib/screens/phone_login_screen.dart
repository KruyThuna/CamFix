import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/otp_sent_dialog.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  static const String _dialCode = '+855';
  final _phone = TextEditingController(text: '97 8068 525');
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
    return n.length >= 8 &&
        n.length <= 9 &&
        !RegExp(r'^(\d)\1+$').hasMatch(n);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendOtp() async {
    if (!_phoneLooksValid) {
      _snack(AppStrings.t('errEnterValidPhone'));
      return;
    }
    setState(() => _sending = true);
    try {
      // Backend OTP — a plain SMS code, no reCAPTCHA / "prove you're not a
      // bot" step. In dev the code comes back in [devCode] (no SMS provider
      // wired); with Twilio configured it is sent by SMS and devCode is null.
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
        _snack(e.message);
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
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 18),
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
