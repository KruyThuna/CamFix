import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Floating pill bottom navigation with 4 items: Home, Bookings, Messages,
/// Account. The bar itself is solid blue; the active tab expands into a wide
/// white pill with its icon + label side by side, while inactive tabs shrink
/// to plain icon-only circles - matching the mockup.
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
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_icons.length, (i) {
          final bool active = i == currentIndex;
          return Expanded(
            flex: active ? 3 : 1,
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: active
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icons[i],
                              color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              AppStrings.t(_labelKeys[i]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Icon(_icons[i],
                        color: AppColors.white.withValues(alpha: 0.9),
                        size: 20),
              ),
            ),
          );
        }),
      ),
    );
  }
}
