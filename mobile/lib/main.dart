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
        defaultValue: 'https://b65bc124cd06722001df13ad9411abbf@o4511590911836160.ingest.us.sentry.io/4511694264860672',
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
