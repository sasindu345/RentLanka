import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/models/notification_item.dart';
import 'package:mobile/core/providers/notification_provider.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical),
              onSelected: (value) {
                if (value == 'read_all') {
                  ref.read(notificationListProvider.notifier).markAllAsRead();
                } else if (value == 'clear_all') {
                  ref.read(notificationListProvider.notifier).clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkSquare, size: 18),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Clear all', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context, theme)
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationCard(context, ref, theme, item);
              },
            ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    NotificationItem item,
  ) {
    // Get appropriate icon and background color depending on notification type
    IconData iconData;
    Color iconColor;
    Color iconBg;

    switch (item.type) {
      case NotificationType.booking:
        iconData = LucideIcons.calendar;
        iconColor = const Color(0xFF10B981); // Emerald
        iconBg = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case NotificationType.message:
        iconData = LucideIcons.messageSquare;
        iconColor = theme.colorScheme.primary; // Blue
        iconBg = theme.colorScheme.primary.withOpacity(0.1);
        break;
      case NotificationType.verification:
        iconData = LucideIcons.shieldCheck;
        iconColor = const Color(0xFF8B5CF6); // Purple
        iconBg = const Color(0xFF8B5CF6).withOpacity(0.1);
        break;
      case NotificationType.system:
        iconData = LucideIcons.bell;
        iconColor = const Color(0xFFF59E0B); // Amber
        iconBg = const Color(0xFFF59E0B).withOpacity(0.1);
        break;
    }

    final String timeAgo = _formatTimeAgo(item.timestamp);

    return InkWell(
      onTap: () {
        if (!item.isRead) {
          ref.read(notificationListProvider.notifier).markAsRead(item.id);
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: item.isRead
                ? theme.colorScheme.outline.withOpacity(0.15)
                : theme.colorScheme.primary.withOpacity(0.3),
            width: item.isRead ? 1.0 : 1.5,
          ),
          boxShadow: theme.brightness == Brightness.dark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // Middle text contents
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: item.isRead ? FontWeight.bold : FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.85),
                      height: 1.3,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.bellOff,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'All caught up!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No new notifications. We will alert you when something important happens.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
