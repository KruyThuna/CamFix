import 'package:flutter/material.dart';

import '../models/technician_profile.dart';
import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _area = TextEditingController();
  String _category = kServiceCategories.first;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password, _area]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if ([_first, _last, _email, _phone, _password, _area]
        .any((c) => c.text.trim().isEmpty)) {
      showError(context, 'Please fill in every field');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthApi.instance.register(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phoneNumber: _phone.text.trim(),
        category: _category,
        serviceArea: _area.text.trim(),
      );
      await CurrentTechnician.instance.refresh();
      if (mounted) Navigator.of(context).pushReplacementNamed('/pending');
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
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('An admin reviews new technicians before you can take jobs.',
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child:
                        LabeledField(label: 'First name', controller: _first)),
                const SizedBox(width: 12),
                Expanded(
                    child: LabeledField(label: 'Last name', controller: _last)),
              ]),
              LabeledField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              LabeledField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone),
              LabeledField(
                  label: 'Password (min 6 characters)',
                  controller: _password,
                  obscure: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text('Service category',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary)),
              ),
              Container(
                decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _category,
                    items: [
                      for (final c in kServiceCategories)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LabeledField(
                  label: 'Service area',
                  controller: _area,
                  hint: 'e.g. Sen Sok, Phnom Penh'),
              const SizedBox(height: 4),
              PrimaryButton(
                  label: 'Register', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
