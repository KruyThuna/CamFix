import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/otp_sent_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack(AppStrings.t('errEnterValidEmail'));
      return;
    }
    setState(() => _sending = true);
    try {
      final otp = await AuthApi.instance.requestEmailOtp(email);
      if (!mounted) return;
      await showOtpSentDialog(context,
          to: email, viaSms: false, devCode: otp.devCode);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/verify-email', arguments: {
        'email': email,
        'mode': 'reset',
        'devCode': otp.devCode,
      });
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
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
              Text(AppStrings.t('forgotWord'), style: AppText.h1),
              Text(AppStrings.t('passwordQWord'), style: AppText.h1),
              const SizedBox(height: 16),
              Text(AppStrings.t('enterYourEmailAddress'), style: AppText.body),
              const SizedBox(height: 10),
              AppTextField(
                hint: AppStrings.t('emailField'),
                icon: Icons.email_outlined,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _sending
                    ? AppStrings.t('sending')
                    : AppStrings.t('send'),
                onPressed: _sending ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
