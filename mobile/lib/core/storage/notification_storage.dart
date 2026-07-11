import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/models/notification_item.dart';

class NotificationStorage {
  static const _prefix = 'rentlanka_notifications_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _keyForUser(String userId) => '$_prefix$userId';

  Future<List<NotificationItem>> loadNotifications(String userId) async {
    final raw = await _storage.read(key: _keyForUser(userId));
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(String userId, List<NotificationItem> notifications) async {
    final raw = jsonEncode(notifications.map((item) => item.toJson()).toList());
    await _storage.write(key: _keyForUser(userId), value: raw);
  }

  Future<void> clearNotifications(String userId) async {
    await _storage.delete(key: _keyForUser(userId));
  }
}