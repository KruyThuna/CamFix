import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../services/saved_card_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

/// Formats digits as "0000 0000 0000 0000" while typing.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '').substring(
        0, newValue.text.replaceAll(RegExp(r'\D'), '').length.clamp(0, 16));
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}

/// Formats digits as "MM/YY" while typing.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '').substring(
        0, newValue.text.replaceAll(RegExp(r'\D'), '').length.clamp(0, 4));
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}

/// Add New Card (mockup). Only the last 4 digits + expiry + holder name are
/// ever kept (in [SavedCardStore], for display purposes) - the full number
/// and CVV are never sent anywhere or stored; there's no real card processor
/// behind this mock checkout.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_holder, _number, _expiry, _cvv]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final digits = _number.text.replaceAll(' ', '');
    if (_holder.text.trim().isEmpty) {
      setState(() => _error = AppStrings.t('cardHolderRequired'));
      return;
    }
    if (digits.length != 16) {
      setState(() => _error = AppStrings.t('cardNumberInvalid'));
      return;
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(_expiry.text)) {
      setState(() => _error = AppStrings.t('cardExpiryInvalid'));
      return;
    }
    if (_cvv.text.length < 3) {
      setState(() => _error = AppStrings.t('cardCvvInvalid'));
      return;
    }
    setState(() => _error = null);
    await SavedCardStore.instance.save(SavedCard(
      holderName: _holder.text.trim(),
      last4: digits.substring(12),
      expiry: _expiry.text,
    ));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(AppStrings.t('addNewCardTitle'),
            style: TextStyle(color: p.textPrimary)),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppLayout.maxPhoneWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppLayout.pageGutter),
              children: [
                AnimatedBuilder(
                  animation: _number,
                  builder: (context, _) => Container(
                    height: 170,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.wifi, color: Colors.white70),
                        const Spacer(),
                        Text(
                          _number.text.isEmpty
                              ? '•••• •••• •••• ••••'
                              : _number.text.padRight(19, '•'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _holder.text.isEmpty
                                  ? AppStrings.t('yourName')
                                  : _holder.text.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              _expiry.text.isEmpty ? 'MM/YY' : _expiry.text,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(AppStrings.t('cardholderName'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: p.textSecondary)),
                const SizedBox(height: 6),
                AppTextField(
                  hint: AppStrings.t('cardholderNameHint'),
                  controller: _holder,
                ),
                const SizedBox(height: 16),
                Text(AppStrings.t('cardNumber'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: p.textSecondary)),
                const SizedBox(height: 6),
                AppTextField(
                  hint: '0000 0000 0000 0000',
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CardNumberFormatter()],
                  maxLength: 19,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.t('expiryDate'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: p.textSecondary)),
                          const SizedBox(height: 6),
                          AppTextField(
                            hint: 'MM/YY',
                            controller: _expiry,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_ExpiryFormatter()],
                            maxLength: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CVV',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: p.textSecondary)),
                          const SizedBox(height: 6),
                          AppTextField(
                            hint: '•••',
                            controller: _cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: Text(AppStrings.t('addCard'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(AppStrings.t('cardEncryptionNote'),
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
