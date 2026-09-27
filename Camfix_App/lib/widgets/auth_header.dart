import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

/// The top hero section shared by Login and Sign Up screens: back button,
/// wavy cyan/blue ribbon background, the robot mascot and the circular
/// CAMFIX logo badge overlapping the white sheet below it.
///
/// Animates in when the screen opens (ribbon + robot slide up and fade in,
/// the logo badge pops in) and the badge then pulses gently - skipped when
/// the device asks for reduced motion.
class AuthHeader extends StatefulWidget {
  const AuthHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<AuthHeader> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _pulse.stop();
    } else if (!_intro.isAnimating && _intro.value == 0) {
      _intro.forward().whenComplete(() {
        if (mounted) _pulse.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _phase(double start, double end, Curve curve) =>
      CurvedAnimation(
          parent: _intro, curve: Interval(start, end, curve: curve));

  @override
  Widget build(BuildContext context) {
    final ribbon = _phase(0, .55, Curves.easeOut);
    final robot = _phase(.15, .75, Curves.easeOutCubic);
    final badge = _phase(.5, 1, Curves.easeOutBack);
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Decorative wave ribbon.
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: ribbon,
              child: Image.asset(
                'assets/images/sharp.png',
                fit: BoxFit.cover,
                height: 580,
              ),
            ),
          ),
          // Back button.
          Positioned(
            top: 0,
            left: 24,
            child: SafeArea(child: CircleBackButton(onPressed: widget.onBack)),
          ),
          // Robot mascot - slides up into place.
          Positioned(
            top: 16,
            child: FadeTransition(
              opacity: robot,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .12), end: Offset.zero)
                    .animate(robot),
                child: const SizedBox(
                  height: 350,
                  child: Image(image: AssetImage('assets/images/robot.png')),
                ),
              ),
            ),
          ),
          // CAMFIX logo badge, overlapping the sheet edge below - pops in,
          // then breathes.
          Positioned(
            bottom: -34,
            child: ScaleTransition(
              scale: badge,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: 1 + .045 * Curves.easeInOut.transform(_pulse.value),
                  child: child,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/camfix_mascot_logo.webp',
                      fit: BoxFit.cover,
                      semanticLabel: 'CamFix',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
