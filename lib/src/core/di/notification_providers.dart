import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_notifications/diti_notifications.dart';

final notificationClientProvider = Provider<NotificationClient>((ref) {
  return FlutterNotificationClient();
});

final localNotificationPortProvider = Provider<LocalNotificationPort>((ref) {
  final client = ref.watch(notificationClientProvider);
  return LocalNotificationPort(client: client);
});

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
  final client = ref.watch(notificationClientProvider);
  return NotificationPermissionService(client: client);
});
