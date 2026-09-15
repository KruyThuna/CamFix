import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Bottom sheet the technician fills in after inspecting a job, to send a
/// real itemized repair quote. Returns `true` if a quote was submitted.
Future<bool> showQuoteFormSheet(
  BuildContext context, {
  required int jobId,
  bool isRevision = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuoteFormSheet(jobId: jobId, isRevision: isRevision),
  );
  return result ?? false;
}

class _QuoteFormSheet extends StatefulWidget {
  const _QuoteFormSheet({required this.jobId, required this.isRevision});
  final int jobId;
  final bool isRevision;

  @override
  State<_QuoteFormSheet> createState() => _QuoteFormSheetState();
}

class _QuoteFormSheetState extends State<_QuoteFormSheet> {
  final _inspection = TextEditingController(text: '0');
  final _labor = TextEditingController(text: '0');
  final _parts = TextEditingController(text: '0');
  final _travel = TextEditingController(text: '0');
  final _reason = TextEditingController();
  bool _submitting = false;

  double get _total =>
      _num(_inspection) + _num(_labor) + _num(_parts) + _num(_travel);

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    for (final c in [_inspection, _labor, _parts, _travel]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_inspection, _labor, _parts, _travel, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await TechnicianApi.instance.submitQuote(
        widget.jobId,
        inspectionFee: _num(_inspection),
        laborCost: _num(_labor),
        partsCost: _num(_parts),
        travelFee: _num(_travel),
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.t(widget.isRevision ? 'sendRevisedQuote' : 'quoteFormTitle'),
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: p.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(AppStrings.t('quoteFormIntro'),
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
              const SizedBox(height: 18),
              LabeledField(
                  label: AppStrings.t('quoteFormInspection'),
                  controller: _inspection,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              LabeledField(
                  label: AppStrings.t('quoteFormLabor'),
                  controller: _labor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              LabeledField(
                  label: AppStrings.t('quoteFormParts'),
                  controller: _parts,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              LabeledField(
                  label: AppStrings.t('quoteFormTravel'),
                  controller: _travel,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              LabeledField(
                label: AppStrings.t('quoteFormReason'),
                controller: _reason,
                hint: AppStrings.t('quoteFormReasonHint'),
                maxLines: 2,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(AppStrings.t('quoteFormTotal'),
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: p.textPrimary)),
                    ),
                    Text('\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.primaryBlue)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: AppStrings.t('quoteFormSubmit'),
                busy: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
