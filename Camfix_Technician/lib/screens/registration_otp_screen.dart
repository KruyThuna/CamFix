import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../services/auth_api.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({
    super.key,
    required this.phone,
    required this.onVerify,
    this.onResend,
    this.devCode,
  });

  final String phone;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function()? onResend;

  /// Code returned by the backend alongside the SMS request while
  /// `app.otp.expose-code=true` (dev/no-SMS-provider builds) - lets testers
  /// verify without a real SMS provider configured.
  final String? devCode;

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen>
    with LangAware<RegistrationOtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  DateTime _resendAt = DateTime.now().add(const Duration(seconds: 60));
  int _seconds = 60;
  bool _busy = false;
  bool _resending = false;
  String? _error;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    if (_devCode != null && _devCode!.isNotEmpty) _code.text = _devCode!;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining =
          (_resendAt.difference(DateTime.now()).inMilliseconds / 1000)
              .ceil()
              .clamp(0, 60);
      if (remaining != _seconds) setState(() => _seconds = remaining);
    });
  }

  Future<void> _verify() async {
    if (_busy || _resending || _code.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onVerify(_code.text);
      if (!mounted) return;
      setState(() => _busy = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : AppStrings.t('otpTryAgain'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _resending || _busy) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      String? devCode;
      if (widget.onResend != null) {
        await widget.onResend!();
      } else {
        final res = await AuthApi.instance.requestRegistrationOtp(widget.phone);
        devCode = res.devCode;
      }
      if (!mounted) return;
      setState(() {
        _devCode = devCode;
        _code.text = devCode ?? '';
        _seconds = 60;
        _resendAt = DateTime.now().add(const Duration(seconds: 60));
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : AppStrings.t('otpTryAgain'));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(actions: const [LanguageToggle()]),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.t('verificationStep3'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const StepDots(step: 3),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.sms_rounded,
                          color: AppColors.primaryBlue,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppStrings.t('confirmPhoneTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.t('smsCodeIntro'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.phone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(AppStrings.t('changePhoneNumber')),
                    ),
                    const SizedBox(height: 24),
                    // One real input supports full-code paste, SMS autofill and backspace.
                    // The six boxes are its visual representation, not six separate inputs.
                    Stack(
                      children: [
                        ExcludeSemantics(
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                for (var i = 0; i < 6; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 58,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: p.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          width: i == _code.text.length ? 2 : 1,
                                          color: _error != null
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                              : i == _code.text.length
                                              ? AppColors.primaryBlue
                                              : p.border,
                                        ),
                                      ),
                                      child: Text(
                                        i < _code.text.length
                                            ? _code.text[i]
                                            : '',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 58,
                          child: TextField(
                            controller: _code,
                            autofocus: true,
                            enabled: !_busy && !_resending,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            showCursor: false,
                            style: const TextStyle(color: Colors.transparent),
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              label: Semantics(
                                label: AppStrings.t('verificationCode'),
                                child: const SizedBox.shrink(),
                              ),
                            ),
                            onChanged: (_) => setState(() => _error = null),
                            onSubmitted: (_) => _verify(),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_devCode != null && _devCode!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          '${AppStrings.t('devModeCodeFilled')} ($_devCode)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textSecondary, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: AppStrings.t('verifyAndRegister'),
                      busy: _busy,
                      onPressed: _code.text.length == 6 && !_resending
                          ? _verify
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.t('noSmsYet'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary),
                    ),
                    TextButton(
                      onPressed: _seconds == 0 && !_resending && !_busy
                          ? _resend
                          : null,
                      child: Text(
                        _resending
                            ? AppStrings.t('sendingSms')
                            : _seconds > 0
                            ? '${AppStrings.t('resendCode')} (${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')})'
                            : AppStrings.t('resendCode'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.t('otpPrivate'),
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
