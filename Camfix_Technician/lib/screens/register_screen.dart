import 'dart:convert';

import 'package:flutter/material.dart';
import 'identity_verification_screen.dart';
import 'registration_otp_screen.dart';

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
  IdentityPhotos? _identityPhotos;
  String? _identityEmail;
  String _category = kServiceCategories.first;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _password, _area]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The field only collects local digits (matching the "+855" prefix shown
  /// beside it) - prepend the country code unless the technician already
  /// typed a full "+..." number themselves.
  String _fullPhone() {
    final raw = _phone.text.trim();
    return raw.startsWith('+') ? raw : '+855$raw';
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).pushNamed('/location-picker');
    if (result is String && result.isNotEmpty) {
      setState(() => _area.text = result);
    }
  }

  Future<void> _submit() async {
    if ([
      _first,
      _last,
      _email,
      _phone,
      _password,
      _area,
    ].any((c) => c.text.trim().isEmpty)) {
      showError(context, AppStrings.t('fillEveryField'));
      return;
    }
    if (_password.text.trim().length < 8) {
      showError(context, AppStrings.t('passwordMin8'));
      return;
    }
    final email = _email.text.trim();
    final photos = await Navigator.of(context).push<IdentityPhotos>(
      MaterialPageRoute(builder: (_) => IdentityVerificationScreen(
        email: email,
        initial: _identityEmail == email ? _identityPhotos : null,
      )),
    );
    if (!mounted || photos == null) return;
    setState(() {
      _identityPhotos = photos;
      _identityEmail = email;
      _busy = true;
    });
    try {
      final phone = _fullPhone();
      final otpRequest = await AuthApi.instance.requestRegistrationOtp(phone);
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => RegistrationOtpScreen(
          phone: phone,
          devCode: otpRequest.devCode,
          onVerify: (code) async {
            await AuthApi.instance.register(
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              email: email,
              password: _password.text,
              phoneNumber: phone,
              category: _category,
              serviceArea: _area.text.trim(),
              idCardBase64: base64Encode(photos.idCard),
              facePhotoBase64: photos.facePhoto == null ? null : base64Encode(photos.facePhoto!),
              emailOtpCode: photos.emailOtpCode,
              otpCode: code,
            );
          },
        )),
      );
      if (!mounted || verified != true) return;
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
            child: Center(child: LanguageToggle()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('registerIntro'),
                style: TextStyle(color: p.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: LabeledField(
                      label: AppStrings.t('firstName'),
                      controller: _first,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledField(
                      label: AppStrings.t('lastName'),
                      controller: _last,
                    ),
                  ),
                ],
              ),
              LabeledField(
                label: AppStrings.t('email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              LabeledField(
                label: AppStrings.t('phoneNumber'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixText: '+855 ',
              ),
              LabeledField(
                label: AppStrings.t('passwordMin8'),
                controller: _password,
                obscure: true,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text(
                  AppStrings.t('serviceCategory'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textSecondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _category,
                    items: [
                      for (final c in kServiceCategories)
                        DropdownMenuItem(
                          value: c,
                          child: Text(AppStrings.category(c)),
                        ),
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
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: AppStrings.t('continueVerification'),
                busy: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              const StepDots(step: 1),
            ],
          ),
        ),
      ),
    );
  }
}
