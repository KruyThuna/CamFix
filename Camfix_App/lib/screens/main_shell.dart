import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';

/// The signed-in shell: Home / Service / Chat / Profile kept alive in one
/// [IndexedStack] so switching tabs never rebuilds a screen or loses its
/// scroll position. Detail screens (provider, chat thread, edit profile…)
/// still push on top of this.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Lets a child screen switch tabs, e.g. `MainShell.of(context)?.goToTab(1)`.
  static MainShellController? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainShellState>();

  @override
  State<MainShell> createState() => _MainShellState();
}

/// The bit of [MainShell] a child is allowed to call.
abstract class MainShellController {
  void goToTab(int index);

  /// Switch to the Service tab and pre-select [category].
  void openServiceCategory(String category);

  /// A category the Service tab should switch to (null once consumed).
  ValueNotifier<String?> get pendingCategory;
}

class _MainShellState extends State<MainShell> implements MainShellController {
  int _index = 0;

  @override
  final ValueNotifier<String?> pendingCategory = ValueNotifier<String?>(null);

  @override
  void goToTab(int index) {
    if (index != _index) setState(() => _index = index);
  }

  @override
  void openServiceCategory(String category) {
    pendingCategory.value = category;
    goToTab(1);
  }

  @override
  void dispose() {
    pendingCategory.dispose();
    super.dispose();
  }

  static const _tabs = [
    DashboardScreen(),
    ServicesScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: context.pal.background,
      body: Stack(
        children: [
          // All four stay mounted (state + scroll preserved); switching
          // cross-fades so the body transition matches the nav-bar pill.
          for (var i = 0; i < _tabs.length; i++)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: i == _index ? 1 : 0,
                child: IgnorePointer(
                  ignoring: i != _index,
                  child: TickerMode(
                    enabled: i == _index,
                    child: _tabs[i],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16 + bottomInset,
            child: CamFixBottomNavBar(
              currentIndex: _index,
              onTap: goToTab,
            ),
          ),
        ],
      ),
    );
  }
}
