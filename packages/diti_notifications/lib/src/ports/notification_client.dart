import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

abstract interface class NotificationClient {
  Future<bool?> initialize({
    required InitializationSettings settings,
    void Function(NotificationResponse response)? onNotificationResponse,
  });

  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation matchDateTimeComponents,
    String? payload,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();

  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails();
}
