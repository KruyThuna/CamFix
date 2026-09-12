import 'package:flutter/widgets.dart';

/// Stub for non-web platforms: `google_sign_in_web` (the real
/// `renderButton`) can only be imported behind a conditional import, since it
/// isn't buildable for Android/iOS.
Widget renderButton() {
  throw StateError('renderButton() is only available on web');
}
