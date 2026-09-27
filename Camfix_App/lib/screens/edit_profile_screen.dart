import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../services/current_user.dart';
import '../services/device_location.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/user_avatar.dart';

/// Edit Profile screen (mockup pages 24–25): editable name / phone / date of
/// birth / address, and a success dialog on save.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _fullName = TextEditingController();
  final _dialCode = TextEditingController(text: '+855');
  late final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final u = CurrentUser.instance.value;
    if (u != null) {
      final name = u.displayName;
      _fullName.text = name == u.email ? '' : name;
      _dob.text = u.dateOfBirth ?? '';
      final phone = u.realPhone;
      if (phone.startsWith('+855')) {
        _phone.text = phone.substring(4).trim();
      } else if (phone.isNotEmpty) {
        _phone.text = phone;
      }
    }
    CurrentUser.instance.refresh();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _dialCode.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Open a calendar; write the chosen day back as ISO `yyyy-MM-dd`.
  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final existing = DateTime.tryParse(_dob.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: AppStrings.t('selectDate'),
    );
    if (picked != null) {
      _dob.text = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  /// Open the map picker; write the chosen point back as "lat, lng".
  Future<void> _pickAddress() async {
    FocusScope.of(context).unfocus();
    final current = _parseLatLng(_address.text);
    final result = await Navigator.of(context)
        .pushNamed('/map-picker', arguments: current);
    if (result is LatLng) {
      _address.text = '${result.latitude.toStringAsFixed(6)}, '
          '${result.longitude.toStringAsFixed(6)}';
      setState(() {});
    }
  }

  /// Read the device GPS and drop the coordinates into the Address field
  /// (same "lat, lng" format the map picker uses, so it round-trips).
  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();
    setState(() => _locating = true);
    final res = await getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (!res.ok) {
      _snack(AppStrings.t(res.errorKey!));
      return;
    }
    _address.text = '${res.position!.latitude.toStringAsFixed(6)}, '
        '${res.position!.longitude.toStringAsFixed(6)}';
    setState(() {});
  }

  static LatLng? _parseLatLng(String s) {
    final m = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(s);
    if (m == null) return null;
    return LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final parts = _fullName.text.trim().split(RegExp(r'\s+'));
      await AuthApi.instance.updateProfile(
        firstName: parts.isNotEmpty ? parts.first : null,
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
        phoneNumber: _phone.text.trim().isEmpty
            ? null
            : '${_dialCode.text.trim()} ${_phone.text.trim()}',
        dateOfBirth: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessDialog(),
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildAvatar(),
                  const SizedBox(height: 28),
                  _label(AppStrings.t('fullName')),
                  _field(controller: _fullName),
                  const SizedBox(height: 18),
                  _label(AppStrings.t('phoneNumber')),
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: _field(
                          controller: _dialCode,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label(AppStrings.t('dateOfBirth')),
                  _field(
                    controller: _dob,
                    readOnly: true,
                    onTap: _pickDob,
                    hint: AppStrings.t('selectDate'),
                    suffixIcon: Icon(Icons.edit_calendar_outlined,
                        size: 20, color: p.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  _label(AppStrings.t('address')),
                  _field(
                    controller: _address,
                    readOnly: true,
                    onTap: _pickAddress,
                    hint: 'SenSok, PhnomPenh, Cambodia',
                    suffixIcon: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            onPressed: _locating ? null : _useCurrentLocation,
                            icon: Icon(Icons.my_location,
                                size: 18, color: p.textSecondary),
                          ),
                  ),
                  const SizedBox(height: 30),
                  PrimaryButton(
                    label: _saving
                        ? AppStrings.t('saving')
                        : AppStrings.t('saveChange'),
                    background: AppColors.primaryBlue,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final p = context.pal;
    return Row(
      children: [
        _circleBackButton(),
        Expanded(
          child: Center(
            child: Text(
              AppStrings.t('editProfile'),
              style: AppText.h2.copyWith(fontSize: 18, color: p.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _circleBackButton() {
    final p = context.pal;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(Icons.arrow_back, color: p.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildAvatar() {
    final p = context.pal;
    return Center(
      child: GestureDetector(
        onTap: () => pickProfilePhoto(context),
        child: SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const UserAvatar(radius: 39),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.background, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera,
                      size: 13, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: context.pal.textSecondary,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextAlign textAlign = TextAlign.start,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hint,
  }) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: textAlign,
        readOnly: readOnly,
        onTap: onTap,
        style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.textSecondary, fontSize: 14),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 17, horizontal: 18),
        ),
      ),
    );
  }
}

/// Centered "Successful" confirmation dialog (mockup page 25).
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.white, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.t('successful'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: PrimaryButton(
                label: AppStrings.t('done'),
                background: AppColors.primaryBlue,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
