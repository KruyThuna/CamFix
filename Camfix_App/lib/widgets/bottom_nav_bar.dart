import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Floating pill bottom navigation with 4 items: Home, Bookings, Messages,
/// Account. Every tab always shows its label; the active one gets a filled
/// blue highlight, matching the mockup.
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
    final p = context.pal;
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_icons.length, (i) {
          final bool active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[i],
                      color: active ? AppColors.white : p.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.t(_labelKeys[i]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? AppColors.white : p.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
