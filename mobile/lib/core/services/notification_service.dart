import 'dart:developer' as developer;
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/notifications_api.dart';
import 'package:mobile/core/api/listings_api.dart';

import 'package:mobile/core/providers/notification_provider.dart';

final notificationServiceProvider = Provider((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  bool _initialized = false;

  NotificationService(this._ref);

  /// Initializes Firebase and Firebase Messaging.
  /// Gracefully catches exceptions if Firebase configuration files are missing.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();
      
      // 2. Request notification permissions
      await requestPermissions();

      // 3. Set up listeners
      _setupMessageListeners();

      _initialized = true;
      developer.log('🔔 Firebase Messaging successfully initialized.');

      // Bootstrap notification cache and device token for the current user, if any.
      await _bootstrapAuthenticatedUser(loadDeviceToken: true);
    } catch (e) {
      developer.log(
        '⚠️ Firebase initialization skipped or failed (config files likely missing). Running in Console/Mock mode.',
        error: e,
      );
    }
  }

  /// Request permissions for iOS and Android 13+ devices
  Future<void> requestPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      developer.log('🔔 Notification Permission Status: ${settings.authorizationStatus}');
    } catch (e) {
      developer.log('⚠️ Error requesting notification permissions: $e');
    }
  }

  /// Fetches FCM token and registers it with the RentLanka API if the user is authenticated.
  Future<void> registerToken() async {
    if (!_initialized) return;

    try {
      await _bootstrapAuthenticatedUser(loadDeviceToken: true);
    } catch (e) {
      developer.log('⚠️ Failed to fetch/register FCM Device Token: $e');
    }
  }

  Future<void> resetForLogout() async {
    _ref.read(notificationListProvider.notifier).reset();
  }

  Future<String?> _bootstrapAuthenticatedUser({required bool loadDeviceToken}) async {
    final listingsApi = _ref.read(listingsApiProvider);
    final isLoggedIn = await listingsApi.isLoggedIn();

    if (!isLoggedIn) {
      developer.log('🔔 Notification bootstrap skipped: User not logged in.');
      _ref.read(notificationListProvider.notifier).reset();
      return null;
    }

    final user = await listingsApi.getCurrentUser();
    await _ref.read(notificationListProvider.notifier).loadForUser(user.id);

    if (!loadDeviceToken) {
      return user.id;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      developer.log('🔔 Found FCM Device Token for user ${user.id}: $token');
      await _ref.read(notificationsApiProvider).registerDeviceToken(token);
      developer.log('🔔 Device token successfully registered with RentLanka API.');
    } else {
      developer.log('⚠️ FCM Device Token was null.');
    }

    return user.id;
  }

  /// Subscribes to foreground/background notification event streams
  void _setupMessageListeners() {
    // 1. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('🔔 Foreground message received: ${message.notification?.title}');
      _showForegroundAlert(message);
    });

    // 2. Listen for tap action when app is opened via notification from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('🔔 App opened via notification: ${message.data}');
      
      final title = message.notification?.title ?? 'Notification Alert';
      final body = message.notification?.body ?? '';
      unawaited(_ref.read(notificationListProvider.notifier).addNotification(title, body));
    });
  }

  /// Displays a non-intrusive floating snackbar alert for foreground notifications
  void _showForegroundAlert(RemoteMessage message) {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? '';

    // Add to history
    unawaited(_ref.read(notificationListProvider.notifier).addNotification(title, body));

    developer.log('🔔 SHOW ALERT: [$title] - $body');
  }
}
