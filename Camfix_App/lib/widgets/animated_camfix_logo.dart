import 'package:flutter/material.dart';
import '../theme/app_images.dart';

/// The official CamFix circular mascot badge matching the user's design.
class AnimatedCamFixLogo extends StatefulWidget {
  const AnimatedCamFixLogo({super.key, this.size = 150.0});

  final double size;

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
    return Semantics(
      label: 'CamFix Mascot Badge',
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Image.asset(
          AppImages.splashBadge,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/camfix_splash_badge.png',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/camfix_mascot_logo.webp',
              width: widget.size,
              height: widget.size,
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
