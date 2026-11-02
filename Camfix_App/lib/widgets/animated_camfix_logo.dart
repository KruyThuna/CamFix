import 'package:flutter/material.dart';

/// Clean animated mascot logo matching the Figma "Page 1 - Splash" design.
class AnimatedCamFixLogo extends StatefulWidget {
  const AnimatedCamFixLogo({super.key});

  /// Soft light background matching the Figma design.
  static const backgroundColor = Color(0xFFF1F3F6);

  @override
  State<AnimatedCamFixLogo> createState() => _AnimatedCamFixLogoState();
}

class _AnimatedCamFixLogoState extends State<AnimatedCamFixLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.95,
    end: 1.05,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Width is approximately 42% of the screen width, matching the Figma splash layout.
    final size = (MediaQuery.sizeOf(context).width * 0.44).clamp(145.0, 185.0);
    return Semantics(
      label: 'CamFix Mascot Logo',
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Image.asset(
          'assets/images/camfix_mascot_logo.webp',
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/logo/camfix_mascot_logo.webp',
            width: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
