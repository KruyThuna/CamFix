import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/tracking_info.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

/// Bottom sheet shown when the "Active" job card is tapped (mockup page 30):
/// service + tracking id, a boxed From / Destination / Technician / Rate /
/// Status panel, a vertical progress stepper and a "Live Tracking" button.
Future<void> showTrackingDetails(BuildContext context, TrackingInfo info) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TrackingSheet(info: info),
  );
}

/// Lavender accent used for the "In Transit" status pill on this sheet.
const Color _statusAccent = Color(0xFF6C63FF);

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({required this.info});
  final TrackingInfo info;

  static const _steps = <(String, String?, IconData)>[
    ('stepBooked', 'stepBookedSub', Icons.assignment_outlined),
    ('inTransit', 'stepInTransitSub', Icons.location_on_outlined),
    ('stepProcessing', 'stepProcessingSub', Icons.build_outlined),
    ('stepCompleted', null, Icons.check_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(AppStrings.t('trackingDetails'),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary)),
                  const Spacer(),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 17, color: p.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Service + tracking id
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.darkButton,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.ac_unit_rounded,
                        color: AppColors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t(info.serviceKey),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '#${AppStrings.t('trackingId')}: '
                                '${info.trackingId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: p.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: info.trackingId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                    content: Text(AppStrings.t('copied')),
                                  ),
                                );
                              },
                              child: const Icon(Icons.content_copy,
                                  size: 14, color: AppColors.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Boxed info panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _field(p, AppStrings.t('fromLabel'),
                              info.originName),
                        ),
                        Expanded(
                          child: _field(p, AppStrings.t('destination'),
                              info.destinationName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _field(p, AppStrings.t('technicianLabel'),
                              info.technicianName),
                        ),
                        Expanded(
                          child: _field(p, AppStrings.t('rateLabel'),
                              '${info.rating}/5'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(AppStrings.t('statusLabel'),
                            style: TextStyle(
                                fontSize: 12, color: p.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
                          decoration: BoxDecoration(
                            color: _statusAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: _statusAccent,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(AppStrings.t('inTransit'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _statusAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              for (var i = 0; i < _steps.length; i++)
                _stepRow(
                  p,
                  title: AppStrings.t(_steps[i].$1),
                  subtitle: _steps[i].$2 == null
                      ? null
                      : AppStrings.t(_steps[i].$2!),
                  icon: _steps[i].$3,
                  reached: i <= info.currentStep,
                  connectorDone: i < info.currentStep,
                  isLast: i == _steps.length - 1,
                ),

              const SizedBox(height: 10),
              PrimaryButton(
                label: AppStrings.t('liveTracking'),
                background: AppColors.primaryBlue,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamed('/live-tracking', arguments: info);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(AppPalette p, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textPrimary)),
      ],
    );
  }

  Widget _stepRow(
    AppPalette p, {
    required String title,
    String? subtitle,
    required IconData icon,
    required bool reached,
    required bool connectorDone,
    required bool isLast,
  }) {
    final circleColor = reached
        ? AppColors.primaryBlue
        : AppColors.primaryBlue.withValues(alpha: 0.16);
    final iconColor =
        reached ? AppColors.white : AppColors.primaryBlue.withValues(alpha: 0.6);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: connectorDone
                        ? AppColors.primaryBlue
                        : AppColors.primaryBlue.withValues(alpha: 0.16),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 4 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: reached
                            ? p.textPrimary
                            : p.textSecondary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: p.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
