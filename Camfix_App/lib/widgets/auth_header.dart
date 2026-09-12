import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

/// The top hero section shared by Login and Sign Up screens: back button,
/// wavy cyan/blue ribbon background, the robot mascot and the circular
/// "CAM FIX" logo badge overlapping the white sheet below it.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
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
            child: Opacity(
              opacity: 1,
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
            child: SafeArea(child: CircleBackButton(onPressed: onBack)),
          ),
          // Robot mascot.
          const Positioned(
            top: 16,
            child: SizedBox(
              height: 350,
              child: Image(image: AssetImage('assets/images/robot.png')),
            ),
          ),
          // Logo badge, overlapping the sheet edge below.
          Positioned(
            bottom: -30,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'CAM\n',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: 'FIX',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
