import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/notifications_api.dart';
import 'package:mobile/core/api/listings_api.dart';

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

      // Try registering token if user is already logged in
      await registerToken();
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
      // Check if user is logged in
      final isLoggedIn = await _ref.read(listingsApiProvider).isLoggedIn();
      if (!isLoggedIn) {
        developer.log('🔔 Notification token registration skipped: User not logged in.');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        developer.log('🔔 Found FCM Device Token: $token');
        await _ref.read(notificationsApiProvider).registerDeviceToken(token);
        developer.log('🔔 Device token successfully registered with RentLanka API.');
      } else {
        developer.log('⚠️ FCM Device Token was null.');
      }
    } catch (e) {
      developer.log('⚠️ Failed to fetch/register FCM Device Token: $e');
    }
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
      // Custom routing/handling can be added here in the future
    });
  }

  /// Displays a non-intrusive floating snackbar alert for foreground notifications
  void _showForegroundAlert(RemoteMessage message) {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? '';

    // Since we don't always have access to a ScaffoldMessenger context at the Service level,
    // we can either trigger a UI provider state or use standard ScaffoldMessenger if a context is active.
    // In this case, we print it to console/logs, and developers can extend this to update local activity states.
    developer.log('🔔 SHOW ALERT: [$title] - $body');
  }
}
