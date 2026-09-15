import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../app_settings.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Preference screen (reached from Profile): distance unit (km/mi) and a
/// default booking address, both purely local (shared_preferences) settings.
class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  Future<void> _pickDefaultAddress() async {
    final settings = AppSettings.instance;
    final start = settings.hasDefaultAddress
        ? LatLng(settings.defaultAddressLat!, settings.defaultAddressLng!)
        : null;
    final result =
        await Navigator.of(context).pushNamed('/map-picker', arguments: start);
    if (result is LatLng) {
      final label = '${result.latitude.toStringAsFixed(6)}, '
          '${result.longitude.toStringAsFixed(6)}';
      await AppSettings.instance
          .setDefaultAddress(label, result.latitude, result.longitude);
      if (mounted) setState(() {});
    }
  }

  Future<void> _clearDefaultAddress() async {
    await AppSettings.instance.clearDefaultAddress();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final settings = AppSettings.instance;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              Text(AppStrings.t('distanceUnit'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _unitChip(
                      context,
                      label: AppStrings.t('kilometers'),
                      selected: settings.distanceUnit == DistanceUnit.km,
                      onTap: () {
                        settings.setDistanceUnit(DistanceUnit.km);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _unitChip(
                      context,
                      label: AppStrings.t('miles'),
                      selected: settings.distanceUnit == DistanceUnit.mi,
                      onTap: () {
                        settings.setDistanceUnit(DistanceUnit.mi);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(AppStrings.t('defaultAddress'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 4),
              Text(AppStrings.t('defaultAddressHint'),
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: p.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: InkWell(
                  onTap: _pickDefaultAddress,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on_outlined,
                              size: 19, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            settings.defaultAddress ?? AppStrings.t('notSet'),
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: settings.hasDefaultAddress
                                    ? p.textPrimary
                                    : p.textSecondary),
                          ),
                        ),
                        if (settings.hasDefaultAddress)
                          TextButton(
                            onPressed: _clearDefaultAddress,
                            child: Text(AppStrings.t('clear')),
                          )
                        else
                          Text(AppStrings.t('setOnMap'),
                              style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.10)
              : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primaryBlue : p.border,
              width: selected ? 1.4 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryBlue : p.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        _circleBackButton(context),
        Expanded(
          child: Center(
            child: Text(
              AppStrings.t('preference'),
              style: AppText.h2.copyWith(fontSize: 20, color: p.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _circleBackButton(BuildContext context) {
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
            BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(Icons.arrow_back, color: p.textPrimary, size: 20),
      ),
    );
  }
}
