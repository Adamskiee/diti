import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:focus_flow_notifications/focus_flow_notifications.dart';

FocusFlowDatabase createInMemoryTestDatabase() {
  return FocusFlowDatabase(NativeDatabase.memory());
}

class FakeNotificationClient implements NotificationClient {
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];

  @override
  Future<bool?> initialize({
    required dynamic settings,
    dynamic onNotificationResponse,
  }) async =>
      true;

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
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async =>
      <PendingNotificationRequest>[];

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async =>
      null;
}
