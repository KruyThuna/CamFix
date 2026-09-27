import 'package:flutter/material.dart';

/// Shared branding for startup and an in-flight sign-in request.
class AnimatedCamFixLogo extends StatefulWidget {
  const AnimatedCamFixLogo({super.key});

  /// White, to match the logo artwork's own white background (and the
  /// native Android launch screen) - a blue background hid the blue logo.
  static const backgroundColor = Color(0xFFFFFFFF);

  @override
  State<AnimatedCamFixLogo> createState() => _AnimatedCamFixLogoState();
}

class _AnimatedCamFixLogoState extends State<AnimatedCamFixLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final size = (MediaQuery.sizeOf(context).width * .55).clamp(150.0, 240.0);
    return Semantics(
      label: 'CamFix',
      image: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
        duration:
            reducedMotion ? Duration.zero : const Duration(milliseconds: 700),
        builder: (context, entrance, child) => Opacity(
          opacity: entrance,
          child: Transform.scale(
            scale: .8 + .2 * Curves.easeOutBack.transform(entrance),
            child: child,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: reducedMotion
                ? 1
                : 1 + .035 * Curves.easeInOut.transform(_controller.value),
            child: child,
          ),
          child: Image.asset(
            'assets/images/camfix_mascot_logo.webp',
            width: size,
            height: size,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
