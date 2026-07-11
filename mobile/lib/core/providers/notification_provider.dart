import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/notification_item.dart';
import 'package:mobile/core/storage/notification_storage.dart';

final notificationStorageProvider = Provider((ref) => NotificationStorage());

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, List<NotificationItem>>((ref) {
  return NotificationListNotifier(ref.watch(notificationStorageProvider));
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(notificationListProvider).any((item) => !item.isRead);
});

class NotificationListNotifier extends StateNotifier<List<NotificationItem>> {
  final NotificationStorage _storage;
  String? _activeUserId;

  NotificationListNotifier(this._storage) : super(const []);

  Future<void> loadForUser(String userId) async {
    _activeUserId = userId;
    state = await _storage.loadNotifications(userId);
  }

  void reset() {
    _activeUserId = null;
    state = const [];
  }

  Future<void> _persist() async {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    await _storage.saveNotifications(userId, state);
  }

  /// Dynamically add a new notification item
  Future<void> addNotification(String title, String body) async {
    if (_activeUserId == null || _activeUserId!.isEmpty) {
      return;
    }

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
    await _persist();
  }

  /// Mark specific notification as read
  Future<void> markAsRead(String id) async {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    await _persist();
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    await _persist();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    state = [];
    final userId = _activeUserId;
    if (userId != null && userId.isNotEmpty) {
      await _storage.clearNotifications(userId);
    }
  }
}
