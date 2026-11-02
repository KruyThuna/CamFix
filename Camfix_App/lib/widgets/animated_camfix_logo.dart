import 'package:flutter/material.dart';

/// Rich animated mascot logo with smooth spring entrance, breathing scale,
/// and pulsing ambient blue glow.
class AnimatedCamFixLogo extends StatefulWidget {
  const AnimatedCamFixLogo({super.key});

  static const backgroundColor = Color(0xFFFFFFFF);

  @override
  State<AnimatedCamFixLogo> createState() => _AnimatedCamFixLogoState();
}

class _AnimatedCamFixLogoState extends State<AnimatedCamFixLogo>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _entranceScale = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _entranceOpacity = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
  );

  late final Animation<double> _pulseAnimation = Tween<double>(
    begin: 1.0,
    end: 1.08,
  ).animate(
    CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),
  );

  late final Animation<double> _glowAnimation = Tween<double>(
    begin: 12.0,
    end: 28.0,
  ).animate(
    CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * .48).clamp(145.0, 195.0);
    return Semantics(
      label: 'CamFix Mascot Logo',
      image: true,
      child: FadeTransition(
        opacity: _entranceOpacity,
        child: ScaleTransition(
          scale: _entranceScale,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                      blurRadius: _glowAnimation.value,
                      spreadRadius: 3,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/camfix_mascot_logo.webp',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/logo/camfix_mascot_logo.webp',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: size,
                      height: size,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
