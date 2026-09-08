import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      showError(context, 'Enter your phone number');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await AuthApi.instance.requestPhoneOtp(phone);
      if (!mounted) return;
      Navigator.pushNamed(context, '/otp',
          arguments: {'phone': phone, 'devCode': res.devCode});
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
      appBar: AppBar(title: const Text('Phone sign in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'We\'ll text a 6-digit code to the number on your technician account.',
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 24),
              LabeledField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 4),
              PrimaryButton(
                  label: 'Send code', busy: _busy, onPressed: _requestCode),
            ],
          ),
        ),
      ),
    );
  }
}
