import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/otp_sent_dialog.dart';
import 'api_client.dart';
import 'auth_api.dart';
import 'token_store.dart';

/// "Continue with Google".
///
/// Shows a Google-style account chooser: pick a Gmail used before (no typing),
/// add another, or remove one. The Spring backend then emails a one-time code
/// to the chosen address. No Firebase, no Google popup, no reCAPTCHA.
Future<void> continueWithGmail(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final known = await TokenStore.instance.knownEmails();
  if (!context.mounted) return;
  final email = await _pickAccount(context, known);
  if (email == null || !context.mounted) return;

  await TokenStore.instance.rememberEmail(email);
  try {
    final otp = await AuthApi.instance.requestEmailOtp(email);
    if (!context.mounted) return;
    await showOtpSentDialog(context,
        to: email, viaSms: false, devCode: otp.devCode);
    if (!context.mounted) return;
    navigator.pushNamed('/verify-email', arguments: {
      'email': email,
      'mode': 'signup',
      'devCode': otp.devCode,
    });
  } on ApiException catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// A rough display name from an email local-part: "kruy.thuna42" -> "Kruy Thuna".
String _nameFromEmail(String email) {
  var local = email.split('@').first;
  local = local.replaceAll(RegExp(r'\d+$'), '');
  final parts = local
      .split(RegExp(r'[._+\-]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .toList();
  return parts.isEmpty ? email : parts.join(' ');
}

const _avatarColors = <Color>[
  Color(0xFFD9483B), // red
  Color(0xFF1A73E8), // blue
  Color(0xFF188038), // green
  Color(0xFFE37400), // amber
  Color(0xFF9334E6), // purple
  Color(0xFF12A4A4), // teal
];

Color _avatarColor(String email) =>
    _avatarColors[email.hashCode.abs() % _avatarColors.length];

/// Bottom sheet: a Google-style account chooser.
Future<String?> _pickAccount(BuildContext context, List<String> known) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AccountSheet(known: List.of(known)),
  );
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({required this.known});
  final List<String> known;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  final _emailCtrl = TextEditingController();
  late List<String> _known = widget.known;
  bool _adding = false; // showing the "add email" input
  bool _removeMode = false; // tapping a row removes it
  String? _error;

  @override
  void initState() {
    super.initState();
    _adding = _known.isEmpty;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submitNew() {
    final v = _emailCtrl.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    Navigator.pop(context, v);
  }

  Future<void> _remove(String email) async {
    await TokenStore.instance.forgetEmail(email);
    if (!mounted) return;
    setState(() {
      _known = _known.where((e) => e != email).toList();
      if (_known.isEmpty) {
        _removeMode = false;
        _adding = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: p.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              _adding
                  ? 'Add an account'
                  : (_removeMode ? 'Remove an account' : 'Choose an account'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          if (_adding) _buildAddView(p) else _buildListView(p),
        ],
      ),
    );
  }

  Widget _buildListView(AppPalette p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final email in _known) ...[
          _divider(p),
          _accountRow(p, email),
        ],
        _divider(p),
        _actionRow(
          p,
          icon: Icons.person_add_alt,
          label: 'Use another account',
          onTap: () => setState(() {
            _adding = true;
            _removeMode = false;
          }),
        ),
        _divider(p),
        _actionRow(
          p,
          icon: Icons.person_remove_alt_1,
          label: _removeMode ? 'Done removing' : 'Remove an account',
          onTap: () => setState(() => _removeMode = !_removeMode),
        ),
        _divider(p),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _divider(AppPalette p) =>
      Divider(height: 1, thickness: 1, color: p.border, indent: 20, endIndent: 20);

  Widget _accountRow(AppPalette p, String email) {
    return InkWell(
      onTap: () =>
          _removeMode ? _remove(email) : Navigator.pop(context, email),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _avatarColor(email),
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameFromEmail(email),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            if (_removeMode)
              Icon(Icons.close, size: 20, color: p.textSecondary)
            else
              Text('Signed out',
                  style: TextStyle(fontSize: 12, color: p.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(AppPalette p,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Icon(icon, size: 22, color: p.textSecondary),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddView(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: TextStyle(color: p.textPrimary),
            decoration: InputDecoration(
              labelText: AppStrings.t('emailField'),
              hintText: 'you@gmail.com',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submitNew(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _known.isEmpty
                      ? Navigator.pop(context)
                      : setState(() => _adding = false),
                  child: Text(AppStrings.t('cancel')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _submitNew,
                  child: Text(AppStrings.t('continue')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
