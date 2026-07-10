import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/app_mode_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/services/signalr_service.dart';

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
    // Auto-connect to real-time WebSocket messaging and notification stream on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalRServiceProvider).connect();
    });

    final theme = Theme.of(context);
    final appMode = ref.watch(appModeProvider);

    final List<_NavItem> items = appMode == UserAppMode.owner
        ? const [
            _NavItem(
              branchIndex: 5,
              icon: LucideIcons.layoutDashboard,
              selectedIcon: LucideIcons.layoutDashboard,
              label: 'Dashboard',
            ),
            _NavItem(
              branchIndex: 2,
              icon: LucideIcons.list,
              selectedIcon: LucideIcons.list,
              label: 'Listings',
            ),
            _NavItem(
              branchIndex: 3,
              icon: LucideIcons.calendar,
              selectedIcon: LucideIcons.calendar,
              label: 'Bookings',
            ),
            _NavItem(
              branchIndex: 6,
              icon: LucideIcons.messageSquare,
              selectedIcon: LucideIcons.messageSquare,
              label: 'Messages',
            ),
            _NavItem(
              branchIndex: 4,
              icon: LucideIcons.user,
              selectedIcon: LucideIcons.user,
              label: 'Profile',
            ),
          ]
        : const [
            _NavItem(
              branchIndex: 0,
              icon: LucideIcons.compass,
              selectedIcon: LucideIcons.compass,
              label: 'Explore',
            ),
            _NavItem(
              branchIndex: 1,
              icon: LucideIcons.heart,
              selectedIcon: LucideIcons.heart,
              label: 'Saved',
            ),
            _NavItem(
              branchIndex: 3,
              icon: LucideIcons.calendar,
              selectedIcon: LucideIcons.calendar,
              label: 'Bookings',
            ),
            _NavItem(
              branchIndex: 6,
              icon: LucideIcons.messageSquare,
              selectedIcon: LucideIcons.messageSquare,
              label: 'Messages',
            ),
            _NavItem(
              branchIndex: 4,
              icon: LucideIcons.user,
              selectedIcon: LucideIcons.user,
              label: 'Profile',
            ),
          ];

    final currentIndexInItems = items.indexWhere((item) => item.branchIndex == navigationShell.currentIndex);
    final selectedIndex = currentIndexInItems != -1 ? currentIndexInItems : items.length - 1;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
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
          ),
        ),
      ),
    );
  }
}
