import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Floating capsule bottom navigation with 4 items: Home, Grid, Chat, Profile.
/// The active "Home" pill expands with a label, matching the mockups.
class CamFixBottomNavBar extends StatelessWidget {
  const CamFixBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];

  static const _labelKeys = ['navHome', 'navService', 'navChat', 'navProfile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_icons.length, (i) {
          final bool active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: active ? 18 : 12,
                vertical: active ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(
                    _icons[i],
                    color: active ? AppColors.primaryBlue : AppColors.white,
                    size: 22,
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.t(_labelKeys[i]),
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
