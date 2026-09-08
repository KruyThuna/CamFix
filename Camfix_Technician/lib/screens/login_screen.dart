import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
              const Icon(Icons.handyman_rounded,
                  size: 44, color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              Text('Technician sign in',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary)),
              const SizedBox(height: 4),
              Text('Use the email and password you registered with.',
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 28),
              LabeledField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              LabeledField(
                  label: 'Password', controller: _password, obscure: true),
              const SizedBox(height: 4),
              PrimaryButton(
                  label: 'Sign in', busy: _busy, onPressed: _submit),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.pushNamed(context, '/phone-login'),
                  child: const Text('Sign in with a phone code instead'),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("New technician?", style: TextStyle(color: p.textSecondary)),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Create an account'),
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
