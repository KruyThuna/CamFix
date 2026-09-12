import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/otp_boxes.dart';

/// Email OTP verification. Reached from Sign Up (`mode: 'signup'` → dashboard on
/// success) and Forgot Password (`mode: 'reset'` → set a new password).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _email = '';
  String _mode = 'signup';
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
      _email = (args['email'] ?? '').toString();
      _mode = (args['mode'] ?? 'signup').toString();
      _devCode = (args['devCode'] as String?)?.trim();
      if (_devCode != null && _devCode!.isEmpty) _devCode = null;
      _code = _devCode ?? '';
    } else if (args is String) {
      _email = args;
      _mode = 'reset';
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
      await AuthApi.instance.verifyEmailOtp(_email, _code);
      if (!mounted) return;
      if (_mode == 'reset') {
        Navigator.of(context).pushNamed('/new-password');
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } on ApiException catch (e) {
      _snack(e.message);
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
      final res = await AuthApi.instance.requestEmailOtp(_email);
      if (!mounted) return;
      setState(() {
        _devCode = res.devCode;
        _code = res.devCode ?? '';
        _boxesKey++;
      });
      _snack(res.devCode != null
          ? 'Dev code: ${res.devCode}'
          : AppStrings.t('newCodeSent'));
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
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
              Text(AppStrings.t('verifyTitle'), style: AppText.h1),
              Text(AppStrings.t('yourEmailTitle'), style: AppText.h1),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: AppText.body,
                  children: [
                    TextSpan(text: AppStrings.t('enterCodeSentTo')),
                    TextSpan(
                      text: _email,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (_devCode != null && _devCode!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Dev: $_devCode — ${AppStrings.t('devCodeFilled')}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OtpBoxes(
                key: ValueKey(_boxesKey),
                length: 6,
                initialValue: _devCode,
                onChanged: (v) => _code = v,
              ),
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
              PrimaryButton(
                label: _verifying
                    ? AppStrings.t('verifying')
                    : AppStrings.t('verifyWord'),
                onPressed: _verifying ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
