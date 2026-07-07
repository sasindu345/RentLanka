import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Async initialization of notifications
  await container.read(notificationServiceProvider).initialize();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: 'https://d9fbb3f7215c4d3da9f1a26bfa33d456@o4507000000000000.ingest.us.sentry.io/4507000000000000', // Production-ready placeholder DSN for Solo dev setup
      );
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      UncontrolledProviderScope(
        container: container,
        child: const RentLankaApp(),
      ),
    ),
  );
}
