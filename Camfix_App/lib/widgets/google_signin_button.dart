import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
import '../services/gmail_connect.dart';
import '../services/web_wrapper.dart' as web;
import 'app_buttons.dart';

/// "Continue with Google" — picks an email straight from a real Google
/// account, never a password typed into this app.
///
/// * Web: renders Google's own Sign-In button (`accounts.google.com`'s
///   widget). Tapping it opens Google's real "choose an account" picker.
/// * Android / iOS: our own button opens the native account chooser via
///   `GoogleSignIn.authenticate()`.
/// * Not configured yet (no `GOOGLE_SIGNIN_CLIENT_ID` dart-define): falls
///   back to emailing a one-time code so sign-in still works.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  static const String _clientId =
      String.fromEnvironment('GOOGLE_SIGNIN_CLIENT_ID');
  static bool get configured => _clientId.isNotEmpty;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _ready = false;
  bool _busy = false;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    if (GoogleSignInButton.configured) _init();
  }

  Future<void> _init() async {
    try {
      await GoogleSignIn.instance
          .initialize(clientId: GoogleSignInButton._clientId);
      GoogleSignIn.instance.authenticationEvents.listen(
        _onEvent,
        onError: (Object e, StackTrace st) => _onError(e),
      );
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('Google sign-in init failed: $e');
      if (mounted) setState(() => _initFailed = true);
    }
  }

  Future<void> _onEvent(GoogleSignInAuthenticationEvent event) async {
    final account = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };
    final idToken = account?.authentication.idToken;
    if (idToken == null) return;

    setState(() => _busy = true);
    try {
      await AuthApi.instance.loginWithGoogle(idToken);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onError(Object e) {
    if (e is GoogleSignInException &&
        e.code == GoogleSignInExceptionCode.canceled) {
      return; // user dismissed the picker
    }
    _snack(e.toString().replaceFirst('Exception: ', ''));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _authenticateNative() async {
    setState(() => _busy = true);
    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _snack(e.description ?? e.code.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleSignInButton.configured || _initFailed) {
      // No Google Cloud OAuth client id set up yet — fall back to picking a
      // remembered Gmail address and emailing it a one-time code.
      return SecondaryButton(
        label: AppStrings.t('continueWithGoogle'),
        leading: const _GoogleG(),
        onPressed: () => continueWithGmail(context),
      );
    }

    if (kIsWeb) {
      if (!_ready) {
        return const SizedBox(
          height: 44,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      // Google's own widget: this IS the real account picker. We don't
      // control what's inside it.
      return SizedBox(height: 44, width: double.infinity, child: web.renderButton());
    }

    return SecondaryButton(
      label: _busy
          ? AppStrings.t('signingIn')
          : AppStrings.t('continueWithGoogle'),
      leading: const _GoogleG(),
      onPressed: _busy ? null : _authenticateNative,
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
