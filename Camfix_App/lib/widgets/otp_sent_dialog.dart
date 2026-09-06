import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Confirmation alert shown right after a one-time code is requested — tells
/// the user a code has gone out by SMS / email (and, in dev, shows the code).
Future<void> showOtpSentDialog(
  BuildContext context, {
  required String to,
  required bool viaSms,
  String? devCode,
}) {
  final p = context.pal;
  final sentLine =
      AppStrings.t(viaSms ? 'otpSentBySms' : 'otpSentByEmail');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(viaSms ? Icons.sms_rounded : Icons.mark_email_read_rounded,
              color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.t('otpSentTitle'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$sentLine\n$to',
              style: TextStyle(fontSize: 14, color: p.textSecondary)),
          if (devCode != null && devCode.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Dev code: $devCode',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppStrings.t('ok')),
        ),
      ],
    ),
  );
}
