import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/service_quote.dart';
import '../services/technician_api.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Bottom sheet the technician fills in after inspecting a job, to send a
/// real itemized repair quote. Returns `true` if a quote was submitted.
Future<bool> showQuoteFormSheet(
  BuildContext context, {
  required int jobId,
  bool isRevision = false,
  bool selfDrop = false,
  double? benchFee,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuoteFormSheet(
      jobId: jobId,
      isRevision: isRevision,
      selfDrop: selfDrop,
      benchFee: benchFee,
    ),
  );
  return result ?? false;
}

class _QuoteFormSheet extends StatefulWidget {
  const _QuoteFormSheet({
    required this.jobId,
    required this.isRevision,
    this.selfDrop = false,
    this.benchFee,
  });
  final int jobId;
  final bool isRevision;

  /// Self Drop: the backend zeroes travel and forces the inspection fee to
  /// the bench fee the customer saw at booking - the form mirrors that.
  final bool selfDrop;
  final double? benchFee;

  bool get lockInspection => selfDrop && benchFee != null;

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

  /// Named line items the customer will approve one by one.
  final List<_ItemDraft> _items = [];

  double get _itemsTotal =>
      _items.fold(0, (s, i) => s + (double.tryParse(i.price.text.trim()) ?? 0));

  double get _total =>
      _num(_inspection) +
      _num(_labor) +
      _num(_parts) +
      (widget.selfDrop ? 0 : _num(_travel)) +
      _itemsTotal;

  void _addItem() {
    final d = _ItemDraft();
    d.price.addListener(() => setState(() {}));
    setState(() => _items.add(d));
  }

  void _removeItem(_ItemDraft d) {
    setState(() => _items.remove(d));
    d.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    if (widget.lockInspection) {
      _inspection.text = widget.benchFee!.toStringAsFixed(2);
    }
    for (final c in [_inspection, _labor, _parts, _travel]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_inspection, _labor, _parts, _travel, _reason]) {
      c.dispose();
    }
    for (final d in _items) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    for (final d in _items) {
      final price = double.tryParse(d.price.text.trim());
      if (d.title.text.trim().isEmpty || price == null || price < 0) {
        showError(context, AppStrings.t('quoteItemInvalid'));
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      await TechnicianApi.instance.submitQuote(
        widget.jobId,
        inspectionFee: _num(_inspection),
        laborCost: _num(_labor),
        partsCost: _num(_parts),
        travelFee: widget.selfDrop ? 0 : _num(_travel),
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        items: [
          for (final d in _items)
            QuoteItem(
              title: d.title.text.trim(),
              price: double.parse(d.price.text.trim()),
              note: d.note.text.trim().isEmpty ? null : d.note.text.trim(),
              recommended: d.recommended,
            ),
        ],
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
          20,
          14,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
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
                AppStrings.t(
                  widget.isRevision ? 'sendRevisedQuote' : 'quoteFormTitle',
                ),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t('quoteFormIntro'),
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
              if (widget.selfDrop) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.t('quoteSelfDropNote'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E9E52),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              IgnorePointer(
                ignoring: widget.lockInspection,
                child: Opacity(
                  opacity: widget.lockInspection ? 0.6 : 1,
                  child: LabeledField(
                    label: AppStrings.t('quoteFormInspection'),
                    controller: _inspection,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ),
              LabeledField(
                label: AppStrings.t('quoteFormLabor'),
                controller: _labor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              LabeledField(
                label: AppStrings.t('quoteFormParts'),
                controller: _parts,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (!widget.selfDrop)
                LabeledField(
                  label: AppStrings.t('quoteFormTravel'),
                  controller: _travel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              LabeledField(
                label: AppStrings.t('quoteFormReason'),
                controller: _reason,
                hint: AppStrings.t('quoteFormReasonHint'),
                maxLines: 2,
              ),
              // Named line items - the customer ticks which ones to do.
              Text(
                AppStrings.t('quoteItemsTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              Text(
                AppStrings.t('quoteItemsHint'),
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              const SizedBox(height: 8),
              for (final d in _items)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: d.title,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: AppStrings.t('quoteItemTitle'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: d.price,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                prefixText: r'$ ',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeItem(d),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: d.note,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: AppStrings.t('quoteItemNote'),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: d.recommended,
                        onChanged: (v) => setState(() => d.recommended = v),
                        title: Text(
                          AppStrings.t('quoteItemRecommended'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          AppStrings.t('quoteItemRecommendedHint'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _items.length >= 20 ? null : _addItem,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppStrings.t('quoteAddItem')),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.t('quoteFormTotal'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.primaryBlue,
                      ),
                    ),
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

/// Editable fields for one line item.
class _ItemDraft {
  final title = TextEditingController();
  final price = TextEditingController();
  final note = TextEditingController();
  bool recommended = false;

  void dispose() {
    title.dispose();
    price.dispose();
    note.dispose();
  }
}
