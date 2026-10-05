import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';
import '../services/app_updater.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/animated_camfix_logo.dart';
import '../widgets/google_signin_button.dart';
import 'login_success_screen.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdater.check(context);
    });
  }

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
      goToDashboardAfterLogin(context);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.message),
            action: SnackBarAction(
              label: 'Server URL',
              textColor: AppColors.cyan,
              onPressed: _showServerDialog,
            ),
            duration: const Duration(seconds: 8),
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    'Live Tunnel',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () => controller.text = ApiConfig.liveTunnelUrl,
                ),
                ActionChip(
                  label: const Text(
                    'api.camapp.store',
                    style: TextStyle(fontSize: 11),
                  ),
                  onPressed: () => controller.text = ApiConfig.domainUrl,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AnimatedCamFixLogo.backgroundColor,
          body: Center(child: AnimatedCamFixLogo()),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                onBack: () =>
                    Navigator.of(context).pushReplacementNamed('/language'),
              ),
              const SizedBox(height: 50),
              // Form fades + slides up just after the header animates in.
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0,
                  end: 1,
                ),
                duration: const Duration(milliseconds: 700),
                curve: const Interval(.35, 1, curve: Curves.easeOutCubic),
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Padding(
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
                              Navigator.of(context)
                                  .pushNamed('/forgot-password'),
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
                              color: AppColors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              AppStrings.t('or'),
                              style: AppText.body,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const GoogleSignInButton(),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/technician'),
                        icon: const Icon(Icons.handyman_outlined),
                        label: const Text('Continue as Technician'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.t('dontHaveAccount'),
                              style: AppText.body,
                            ),
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
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: _showServerDialog,
                          icon: const Icon(
                            Icons.dns_outlined,
                            size: 14,
                            color: Colors.white60,
                          ),
                          label: Text(
                            'Server: ${ApiConfig.baseUrl}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
