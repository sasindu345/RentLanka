import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/notification_item.dart';

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, List<NotificationItem>>((ref) {
  return NotificationListNotifier();
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(notificationListProvider).any((item) => !item.isRead);
});

class NotificationListNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationListNotifier() : super(_initialMockNotifications);

  static final List<NotificationItem> _initialMockNotifications = [
    NotificationItem(
      id: 'mock-1',
      title: 'Booking Request Accepted',
      body: 'Your request to rent the "Sony Alpha 7 IV Camera" has been approved by the host.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isRead: false,
      type: NotificationType.booking,
    ),
    NotificationItem(
      id: 'mock-2',
      title: 'New Message from Priyantha',
      body: '"Hello! Sure, the camera is fully charged and ready for pick-up. Let me know..."',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.message,
    ),
    NotificationItem(
      id: 'mock-3',
      title: 'Identity Verification Success',
      body: 'Congratulations! Your profile has been upgraded to Verified (Email & NIC Verification completed).',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.verification,
    ),
    NotificationItem(
      id: 'mock-4',
      title: 'Welcome to RentLanka!',
      body: 'Start listing your idle gear to earn passive income, or explore items to rent from peers nearby.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      type: NotificationType.system,
    ),
  ];

  /// Dynamically add a new notification item
  void addNotification(String title, String body) {
    // Determine the type dynamically based on content matching
    NotificationType type = NotificationType.system;
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    
    if (lowerTitle.contains('booking') || lowerBody.contains('booking') || lowerTitle.contains('rent')) {
      type = NotificationType.booking;
    } else if (lowerTitle.contains('message') || lowerBody.contains('message') || lowerTitle.contains('chat')) {
      type = NotificationType.message;
    } else if (lowerTitle.contains('verify') || lowerBody.contains('verify') || lowerTitle.contains('nic')) {
      type = NotificationType.verification;
    }

    final newNotification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );

    state = [newNotification, ...state];
  }

  /// Mark specific notification as read
  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  /// Mark all as read
  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }

  /// Clear all notifications
  void clearAll() {
    state = [];
  }
}
