import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/providers/notification_provider.dart';
import 'package:mobile/features/profile/screens/notifications_screen.dart';

class NotificationBellButton extends ConsumerWidget {
  final Color? color;
  const NotificationBellButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);
    final iconColor = color ?? theme.colorScheme.onBackground;

    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            LucideIcons.bell,
            color: iconColor,
            size: 24,
          ),
          if (hasUnread)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
