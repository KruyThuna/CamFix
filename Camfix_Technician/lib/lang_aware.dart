import 'package:flutter/widgets.dart';

import 'app_settings.dart';

/// Mix into a screen's `State` so it rebuilds the instant the app language
/// changes.
///
/// The top-level `AnimatedBuilder` in `main.dart` only rebuilds `MaterialApp`;
/// that does not reach routes already on the Navigator stack (their content is
/// cached by `_ModalScope`). Screens that show translated text — or a language
/// control — need to listen for themselves.
mixin LangAware<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }
}
