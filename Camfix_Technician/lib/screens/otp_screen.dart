import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/current_technician.dart';
import '../theme/app_theme.dart';
import '../widgets/otp_boxes.dart';
import '../widgets/ui.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = '';
  bool _busy = false;

  Future<void> _verify(String phone) async {
    if (_code.length < 6) {
      showError(context, 'Enter the 6-digit code');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthApi.instance.verifyPhoneOtp(phone, _code);
      await CurrentTechnician.instance.refresh();
      if (!mounted) return;
      final p = CurrentTechnician.instance.value;
      Navigator.of(context).pushNamedAndRemoveUntil(
        p != null && p.isApproved && !p.isSuspended ? '/home' : '/pending',
        (r) => false,
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {})
        as Map<String, dynamic>;
    final phone = (args['phone'] ?? '').toString();
    final devCode = args['devCode']?.toString();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blueGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text('Enter code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Sent to $phone',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 28),
                OtpBoxes(
                  initialValue: devCode,
                  onChanged: (v) => _code = v,
                ),
                if (devCode != null && devCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text('Dev mode: code $devCode filled in for you',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                const SizedBox(height: 28),
                PrimaryButton(
                    label: 'Verify',
                    busy: _busy,
                    onPressed: () => _verify(phone)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
