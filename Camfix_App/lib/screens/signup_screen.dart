import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/otp_sent_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signUp() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      _snack(AppStrings.t('errEnterValidEmail'));
      return;
    }
    if (password.length < 6) {
      _snack(AppStrings.t('errPasswordMin'));
      return;
    }
    if (password != _confirm.text) {
      _snack(AppStrings.t('errPasswordsDontMatch'));
      return;
    }
    setState(() => _loading = true);
    try {
      // 1. create the account, 2. email a code to verify the address.
      await AuthApi.instance.register(email, password);
      final otp = await AuthApi.instance.requestEmailOtp(email);
      if (!mounted) return;
      await showOtpSentDialog(context,
          to: email, viaSms: false, devCode: otp.devCode);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/verify-email', arguments: {
        'email': email,
        'mode': 'signup',
        'devCode': otp.devCode,
      });
    } on ApiException catch (e) {
      _snack(e.message); // e.g. "Email already registered: …"
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(),
              const SizedBox(height: 44),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      hint: AppStrings.t('emailField'),
                      icon: Icons.email_outlined,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      hint: AppStrings.t('passwordField'),
                      icon: Icons.lock_outline,
                      controller: _password,
                      obscureText: _obscure1,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure1
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.hintGrey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      hint: AppStrings.t('confirmPasswordField'),
                      icon: Icons.lock_outline,
                      controller: _confirm,
                      obscureText: _obscure2,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.hintGrey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _loading
                          ? AppStrings.t('creatingAccount')
                          : AppStrings.t('signUp'),
                      onPressed: _loading ? null : _signUp,
                    ),
                    const SizedBox(height: 14),
                    SecondaryButton(
                      label: AppStrings.t('loginWithPhone'),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/phone-login'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: AppColors.white.withValues(alpha: 0.4))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(AppStrings.t('or'), style: AppText.body),
                        ),
                        Expanded(
                            child: Divider(
                                color: AppColors.white.withValues(alpha: 0.4))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const GoogleSignInButton(),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppStrings.t('alreadyHaveAccount'),
                              style: AppText.body),
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                            child: Text(
                              AppStrings.t('login'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
