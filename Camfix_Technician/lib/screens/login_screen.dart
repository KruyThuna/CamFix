import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with LangAware<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await AuthApi.instance.login(_email.text.trim(), _password.text);
      await CurrentTechnician.instance.refresh();
      if (!mounted) return;
      final p = CurrentTechnician.instance.value;
      Navigator.of(context).pushReplacementNamed(
        p != null && p.isApproved && !p.isSuspended ? '/home' : '/pending',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: const LanguageToggle()),
              const SizedBox(height: 4),
              const Icon(Icons.handyman_rounded,
                  size: 44, color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              Text(AppStrings.t('loginTitle'),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 4),
              Text(AppStrings.t('loginSubtitle'),
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 28),
              LabeledField(
                  label: AppStrings.t('email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              LabeledField(
                  label: AppStrings.t('password'),
                  controller: _password,
                  obscure: true),
              const SizedBox(height: 4),
              PrimaryButton(
                  label: AppStrings.t('signInBtn'),
                  busy: _busy,
                  onPressed: _submit),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.pushNamed(context, '/phone-login'),
                  child: Text(AppStrings.t('signInWithPhone')),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.t('newTechnicianQ'),
                      style: TextStyle(color: p.textSecondary)),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.pushNamed(context, '/register'),
                    child: Text(AppStrings.t('createAccount')),
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
