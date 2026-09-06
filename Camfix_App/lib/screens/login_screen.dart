import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/google_signin_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _snack(AppStrings.t('errEnterEmailAndPassword'));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthApi.instance.login(email, password);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } on ApiException catch (e) {
      _snack(e.message); // e.g. "Invalid email or password"
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
                      hint: AppStrings.t('email'),
                      icon: Icons.email_outlined,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      hint: AppStrings.t('passwordField'),
                      icon: Icons.lock_outline,
                      controller: _password,
                      obscureText: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.hintGrey,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.t('forgotPasswordQ'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: _loading
                          ? AppStrings.t('signingIn')
                          : AppStrings.t('signIn'),
                      onPressed: _loading ? null : _signIn,
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
                          Text(AppStrings.t('dontHaveAccount'),
                              style: AppText.body),
                          GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pushNamed('/signup'),
                            child: Text(
                              AppStrings.t('signUp'),
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
