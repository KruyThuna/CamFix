import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
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

class _RegisterScreenState extends State<RegisterScreen>
    with LangAware<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _area = TextEditingController();
  final _otpCode = TextEditingController();
  String _category = kServiceCategories.first;
  bool _busy = false;
  bool _otpSent = false;
  bool _sendingOtp = false;
  String? _devCode;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password, _area, _otpCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      showError(context, AppStrings.t('enterPhoneFirst'));
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      final result = await AuthApi.instance.requestRegistrationOtp(phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _devCode = result.devCode;
        if (result.devCode != null && result.devCode!.isNotEmpty) {
          _otpCode.text = result.devCode!;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('codeSentToPhone'))));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).pushNamed('/location-picker');
    if (result is String && result.isNotEmpty) {
      setState(() => _area.text = result);
    }
  }

  Future<void> _submit() async {
    if ([_first, _last, _email, _phone, _password, _area]
        .any((c) => c.text.trim().isEmpty)) {
      showError(context, AppStrings.t('fillEveryField'));
      return;
    }
    if (!_otpSent || _otpCode.text.trim().length < 6) {
      showError(context, AppStrings.t('verifyPhoneFirst'));
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
        otpCode: _otpCode.text.trim(),
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
      appBar: AppBar(
        title: Text(AppStrings.t('createAccountTitle')),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(child: LanguageToggle())),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t('registerIntro'),
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: LabeledField(
                        label: AppStrings.t('firstName'), controller: _first)),
                const SizedBox(width: 12),
                Expanded(
                    child: LabeledField(
                        label: AppStrings.t('lastName'), controller: _last)),
              ]),
              LabeledField(
                  label: AppStrings.t('email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              LabeledField(
                  label: AppStrings.t('phoneNumber'),
                  controller: _phone,
                  keyboardType: TextInputType.phone),
              if (!_otpSent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _sendingOtp ? null : _sendOtp,
                      icon: _sendingOtp
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.sms_outlined, size: 18),
                      label: Text(AppStrings.t('sendVerificationCode')),
                    ),
                  ),
                )
              else ...[
                LabeledField(
                    label: AppStrings.t('verificationCode'),
                    controller: _otpCode,
                    keyboardType: TextInputType.number),
                if (_devCode != null && _devCode!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                        '${AppStrings.t('devModeCodeFilled')} ($_devCode)',
                        style: TextStyle(fontSize: 12, color: p.textSecondary)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _sendingOtp ? null : _sendOtp,
                      child: Text(AppStrings.t('resendCode')),
                    ),
                  ),
                ),
              ],
              LabeledField(
                  label: AppStrings.t('passwordMin6'),
                  controller: _password,
                  obscure: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text(AppStrings.t('serviceCategory'),
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
                        DropdownMenuItem(
                            value: c, child: Text(AppStrings.category(c))),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LabeledField(
                  label: AppStrings.t('serviceArea'),
                  controller: _area,
                  hint: AppStrings.t('serviceAreaHint'),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined),
                    tooltip: AppStrings.t('pickOnMap'),
                    onPressed: _pickLocation,
                  )),
              const SizedBox(height: 4),
              PrimaryButton(
                  label: AppStrings.t('registerBtn'),
                  busy: _busy,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
