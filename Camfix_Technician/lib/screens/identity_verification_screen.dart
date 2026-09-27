import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'selfie_camera_screen.dart';

class IdentityPhotos {
  const IdentityPhotos(this.idCard, {this.facePhoto, this.emailOtpCode})
      : assert(
          facePhoto != null || emailOtpCode != null,
          'Provide a face photo or an email verification code',
        );
  final Uint8List idCard;

  /// Null when verified via [emailOtpCode] instead.
  final Uint8List? facePhoto;

  /// Six-digit code sent to the technician's email, entered during this
  /// screen - null when a [facePhoto] was taken instead. Checked once, by
  /// the backend, at final registration submission.
  final String? emailOtpCode;
}

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({
    super.key,
    required this.email,
    this.initial,
  });

  /// The technician's account email (already collected on the registration
  /// form) - where the alternative verification code gets sent.
  final String email;
  final IdentityPhotos? initial;

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen>
    with LangAware<IdentityVerificationScreen> {
  Uint8List? _idCard;
  Uint8List? _facePhoto;
  bool _picking = false;

  final _emailCodeController = TextEditingController();
  bool _emailCodeSent = false;
  bool _sendingEmailCode = false;

  @override
  void initState() {
    super.initState();
    _idCard = widget.initial?.idCard;
    _facePhoto = widget.initial?.facePhoto;
    _emailCodeController.text = widget.initial?.emailOtpCode ?? '';
    // Re-evaluate the submit button's enabled state as the code is typed.
    _emailCodeController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailCodeController.dispose();
    super.dispose();
  }

  /// A face photo taken and an email code entered are alternatives, not both
  /// required - taking a new photo clears any in-progress email code and
  /// vice versa, so [IdentityPhotos]'s "exactly one" invariant always holds.
  void _useFacePhotoInstead() {
    setState(() {
      _emailCodeSent = false;
      _emailCodeController.clear();
    });
  }

  Future<void> _sendEmailCode() async {
    setState(() => _sendingEmailCode = true);
    try {
      await AuthApi.instance.requestEmailOtp(widget.email);
      if (!mounted) return;
      setState(() {
        _emailCodeSent = true;
        _facePhoto = null;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sendingEmailCode = false);
    }
  }

  Future<void> _pickId(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) showError(context, AppStrings.t('photoTooLarge'));
        return;
      }
      final bytes = await file.readAsBytes();
      // Restrict document types before previewing or sending them.
      final jpeg =
          bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      final png =
          bytes.length >= 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      if (!jpeg && !png) {
        if (mounted) showError(context, AppStrings.t('idCardInvalid'));
        return;
      }
      if (mounted) setState(() => _idCard = bytes);
    } catch (_) {
      if (mounted) showError(context, AppStrings.t('idCardInvalid'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _takeFacePhoto() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const SelfieCameraScreen()),
    );
    if (mounted && bytes != null) {
      setState(() {
        _facePhoto = bytes;
        _emailCodeSent = false;
        _emailCodeController.clear();
      });
    }
  }

  /// "Don't want to take a face photo? Verify by email instead" - sits below
  /// the ID/face cards. Mutually exclusive with [_facePhoto]: sending a code
  /// clears any captured photo and vice versa.
  Widget _emailAlternativeCard() {
    final p = context.pal;
    if (_facePhoto != null) {
      // A face photo is already in hand - keep this collapsed to a single
      // low-emphasis link rather than competing with it.
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _sendingEmailCode ? null : _sendEmailCode,
          icon: const Icon(Icons.alternate_email, size: 18),
          label: Text(AppStrings.t('verifyByEmailInstead')),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alternate_email, color: AppColors.primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.t('verifyByEmailTitle'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _emailCodeSent
                ? AppStrings.t('verifyByEmailCodeSent').replaceAll(
                    '{email}',
                    widget.email,
                  )
                : AppStrings.t('verifyByEmailHelp').replaceAll(
                    '{email}',
                    widget.email,
                  ),
            style: TextStyle(color: p.textSecondary),
          ),
          const SizedBox(height: 14),
          if (!_emailCodeSent)
            OutlinedButton.icon(
              onPressed: _sendingEmailCode ? null : _sendEmailCode,
              icon: _sendingEmailCode
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(AppStrings.t('sendEmailCode')),
            )
          else ...[
            TextField(
              controller: _emailCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: AppStrings.t('emailCodeLabel'),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _sendingEmailCode ? null : _sendEmailCode,
                  child: Text(AppStrings.t('resendEmailCode')),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _useFacePhotoInstead,
                  child: Text(AppStrings.t('useFacePhotoInstead')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoCard({
    required String step,
    required String title,
    required String help,
    required IconData icon,
    required Uint8List? photo,
    required List<Widget> actions,
    bool face = false,
  }) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: p.surfaceAlt,
                child: Text(
                  step,
                  style: const TextStyle(color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.t(title),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (photo != null)
                const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          Text(AppStrings.t(help), style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(18),
            ),
            child: face
                ? Center(
                    child: Container(
                      width: 192,
                      height: 240,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: p.border),
                        boxShadow: [BoxShadow(color: p.shadow,
                            blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: photo == null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_outlined, size: 72,
                                    color: AppColors.primaryBlue.withValues(alpha: .5)),
                                const SizedBox(height: 12),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(AppStrings.t('faceFrameHint'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: p.textSecondary, fontSize: 12))),
                              ])
                          : Image.memory(photo, fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined)),
                    ),
                  )
                : photo == null
                ? Icon(
                    icon,
                    size: 76,
                    color: AppColors.primaryBlue.withValues(alpha: .45),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.memory(
                            photo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                Text(AppStrings.t('idCardInvalid')),
                          ),
                  ),
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validEmailCode = RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(_emailCodeController.text.trim());
    final ready =
        _idCard != null &&
        (_facePhoto != null || validEmailCode) &&
        !_picking;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('verifyIdentityTitle')),
        actions: const [LanguageToggle()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  AppStrings.t('verificationStep'),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const StepDots(step: 2),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t('verifyIdentityIntro'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final id = _photoCard(
                      step: '1',
                      title: 'idCardTitle',
                      help: 'idCardHelp',
                      icon: Icons.badge_outlined,
                      photo: _idCard,
                      actions: [
                        OutlinedButton.icon(
                          onPressed: _picking
                              ? null
                              : () => _pickId(ImageSource.gallery),
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            AppStrings.t(
                              _idCard == null
                                  ? 'selectIdCard'
                                  : 'replaceIdCard',
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          onPressed: _picking
                              ? null
                              : () => _pickId(ImageSource.camera),
                          tooltip: AppStrings.t('takePhoto'),
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                      ],
                    );
                    final face = _photoCard(
                      step: '2',
                      title: 'facePhotoTitle',
                      help: 'facePhotoHelp',
                      icon: Icons.face_outlined,
                      photo: _facePhoto,
                      face: true,
                      actions: [
                        SizedBox(width: double.infinity, child: FilledButton.icon(
                          onPressed: _picking ? null : _takeFacePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: _facePhoto == null
                                ? AppColors.primaryBlue : context.pal.surfaceAlt,
                            foregroundColor: _facePhoto == null
                                ? Colors.white : AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          label: Text(
                            AppStrings.t(
                              _facePhoto == null
                                  ? 'openFaceCamera'
                                  : 'retakeFacePhoto',
                            ),
                          ),
                        )),
                      ],
                    );
                    return constraints.maxWidth >= 680
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: id),
                              const SizedBox(width: 20),
                              Expanded(child: face),
                            ],
                          )
                        : Column(
                            children: [id, const SizedBox(height: 20), face],
                          );
                  },
                ),
                const SizedBox(height: 20),
                _emailAlternativeCard(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.t('identityReviewNote'),
                        style: TextStyle(color: context.pal.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: AppStrings.t('submitIdentity'),
                  onPressed: ready
                      ? () => Navigator.pop(
                          context,
                          IdentityPhotos(
                            _idCard!,
                            facePhoto: _facePhoto,
                            emailOtpCode: _facePhoto == null
                                ? _emailCodeController.text.trim()
                                : null,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
