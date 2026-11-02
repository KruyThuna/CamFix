import 'package:flutter/material.dart';

/// The official CamFix circular mascot badge matching the user design.
class AnimatedCamFixLogo extends StatefulWidget {
  const AnimatedCamFixLogo({super.key});

  /// Soft light background matching the Figma splash screen.
  static const backgroundColor = Color(0xFFF1F3F6);

  @override
  State<AnimatedCamFixLogo> createState() => _AnimatedCamFixLogoState();
}

class _AnimatedCamFixLogoState extends State<AnimatedCamFixLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.96,
    end: 1.04,
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
    // 160x160 circular badge with 18px padding ensures the mascot and
    // the "CAM FIX" pill fit completely inside with generous white margins
    // without any clipping.
    const size = 160.0;
    return Semantics(
      label: 'CamFix Mascot Badge',
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo/camfix_mascot_logo.webp',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/camfix_mascot_logo.webp',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.handyman_rounded,
                size: 64,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
