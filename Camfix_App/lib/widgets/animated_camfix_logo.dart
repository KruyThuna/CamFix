import 'package:flutter/material.dart';
import '../theme/app_images.dart';

/// Clean standalone CamFix mascot logo without any circular border or disc,
/// exactly matching the user request.
class AnimatedCamFixLogo extends StatefulWidget {
  const AnimatedCamFixLogo({super.key, this.size = 180.0});

  final double size;

  /// Pure white background.
  static const backgroundColor = Color(0xFFFFFFFF);

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
          AppImages.mascotLogo,
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
              size: 72,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }
}
