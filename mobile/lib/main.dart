import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Async initialization of notifications
  await container.read(notificationServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RentLankaApp(),
    ),
  );
}
