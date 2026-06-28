import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';

class _NavItem {
  final int branchIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.branchIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class BottomNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(appModeProvider);

    final List<_NavItem> items = appMode == UserAppMode.owner
        ? const [
            _NavItem(
              branchIndex: 2,
              icon: Icons.add_circle_outline,
              selectedIcon: Icons.add_circle,
              label: 'List',
            ),
            _NavItem(
              branchIndex: 3,
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month,
              label: 'Activity',
            ),
            _NavItem(
              branchIndex: 4,
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
            ),
          ]
        : const [
            _NavItem(
              branchIndex: 0,
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore,
              label: 'Explore',
            ),
            _NavItem(
              branchIndex: 1,
              icon: Icons.favorite_outline,
              selectedIcon: Icons.favorite,
              label: 'Saved',
            ),
            _NavItem(
              branchIndex: 3,
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month,
              label: 'Activity',
            ),
            _NavItem(
              branchIndex: 4,
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
            ),
          ];

    final currentIndexInItems = items.indexWhere((item) => item.branchIndex == navigationShell.currentIndex);
    final selectedIndex = currentIndexInItems != -1 ? currentIndexInItems : items.length - 1;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final targetBranch = items[index].branchIndex;
          navigationShell.goBranch(targetBranch);
        },
        destinations: items.map((item) => NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: item.label,
        )).toList(),
      ),
    );
  }
}
