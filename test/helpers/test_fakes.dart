import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_notifications/diti_notifications.dart';

DitiDatabase createInMemoryTestDatabase() {
  return DitiDatabase(NativeDatabase.memory());
}

class FakeNotificationClient implements NotificationClient {
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];
  bool isInitialized = false;
  InitializationSettings? initializationSettings;

  @override
  Future<bool?> initialize({
    required dynamic settings,
    dynamic onNotificationResponse,
  }) async {
    isInitialized = true;
    initializationSettings = settings as InitializationSettings?;
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required dynamic scheduledDate,
    required dynamic notificationDetails,
    required dynamic androidScheduleMode,
    required dynamic matchDateTimeComponents,
    String? payload,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelledIds.addAll(scheduledIds);
  }

  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => <PendingNotificationRequest>[];

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async => null;
}

class FakePermissionService implements NotificationPermissionService {
  NotificationPermissionStatus status;

  FakePermissionService({
    this.status = const NotificationPermissionStatus(
      notificationsEnabled: true,
      exactAlarmsAllowed: true,
    ),
  });

  @override
  Future<NotificationPermissionStatus> checkStatus() async => status;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<bool> requestNotificationPermissions() async => true;
}
