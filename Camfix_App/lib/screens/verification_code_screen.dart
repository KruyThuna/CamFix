import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/otp_boxes.dart';

/// Confirms the OTP the backend issued for the user's phone number
/// (`/api/auth/phone/*`) — a plain SMS code, no bot / reCAPTCHA check.
class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  String _phone = '';
  String? _devCode;
  String _code = '';
  bool _verifying = false;
  bool _resending = false;
  int _boxesKey = 0;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _phone = (args['phone'] ?? '').toString();
      _devCode = (args['devCode'] as String?)?.trim();
      if (_devCode != null && _devCode!.isEmpty) _devCode = null;
      _code = _devCode ?? '';
    } else if (args is String) {
      _phone = args;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      _snack(AppStrings.t('errEnter6DigitCode'));
      return;
    }
    setState(() => _verifying = true);
    try {
      await AuthApi.instance.verifyPhoneOtp(_phone, _code);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _snack(_readable(e)); // wrong code / expired / network
      setState(() {
        _code = '';
        _boxesKey++;
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final res = await AuthApi.instance.requestPhoneOtp(_phone);
      if (!mounted) return;
      setState(() {
        _devCode = res.devCode;
        _code = res.devCode ?? '';
        _boxesKey++;
        _resending = false;
      });
      _snack(res.devCode != null
          ? 'Dev code: ${res.devCode}'
          : AppStrings.t('newCodeSent'));
    } catch (e) {
      if (mounted) {
        setState(() => _resending = false);
        _snack(_readable(e));
      }
    }
  }

  String _readable(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
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
              Text(AppStrings.t('verification'), style: AppText.h1),
              Text(AppStrings.t('codeWord'), style: AppText.h1),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: AppText.body,
                  children: [
                    TextSpan(text: AppStrings.t('weSentCodeTo')),
                    TextSpan(
                      text: _phone.replaceAll(' ', ''),
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OtpBoxes(
                key: ValueKey(_boxesKey),
                length: 6,
                initialValue: _devCode,
                onChanged: (v) => _code = v,
              ),
              if (_devCode != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Dev: $_devCode — ${AppStrings.t('devCodeFilled')}',
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    color: AppColors.cyan,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(AppStrings.t('didntGetCode'), style: AppText.body),
                  GestureDetector(
                    onTap: _resending ? null : _resend,
                    child: Text(
                      _resending
                          ? AppStrings.t('sending')
                          : AppStrings.t('clickToResend'),
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: AppStrings.t('cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PrimaryButton(
                      label: _verifying
                          ? AppStrings.t('verifying')
                          : AppStrings.t('verifyWord'),
                      onPressed: _verifying ? null : _verify,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
