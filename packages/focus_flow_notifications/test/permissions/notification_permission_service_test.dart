import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow_notifications/src/permissions/notification_permission_service.dart';

class FakePermissionService implements NotificationPermissionService {
  bool notificationsEnabled = true;
  bool exactAlarmsAllowed = true;

  @override
  Future<NotificationPermissionStatus> checkStatus() async {
    return NotificationPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );
  }

  @override
  Future<bool> requestNotificationPermissions() async => notificationsEnabled;

  @override
  Future<bool> requestExactAlarmPermission() async => exactAlarmsAllowed;
}

void main() {
  group('NotificationPermissionStatus', () {
    test('canDeliverReliably is true only when both notifications and exact alarms allowed', () {
      const full = NotificationPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsAllowed: true,
      );
      expect(full.canDeliverReliably, isTrue);
      expect(full.needsInAppNotice, isFalse);

      const noExact = NotificationPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsAllowed: false,
      );
      expect(noExact.canDeliverReliably, isFalse);
      expect(noExact.needsInAppNotice, isTrue);

      const noNotifications = NotificationPermissionStatus(
        notificationsEnabled: false,
        exactAlarmsAllowed: true,
      );
      expect(noNotifications.canDeliverReliably, isFalse);
      expect(noNotifications.needsInAppNotice, isTrue);

      const none = NotificationPermissionStatus(
        notificationsEnabled: false,
        exactAlarmsAllowed: false,
      );
      expect(none.canDeliverReliably, isFalse);
      expect(none.needsInAppNotice, isTrue);
    });

    test('toString returns informative representation', () {
      const status = NotificationPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsAllowed: false,
      );
      expect(
        status.toString(),
        'NotificationPermissionStatus(notifications: true, exactAlarms: false)',
      );
    });

    test('equality and hashCode compare field values correctly', () {
      const a1 = NotificationPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsAllowed: true,
      );
      const a2 = NotificationPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsAllowed: true,
      );
      const b = NotificationPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsAllowed: false,
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(b)));
    });

    test('FakePermissionService reports consistent status', () async {
      final service = FakePermissionService();
      service.notificationsEnabled = false;

      final status = await service.checkStatus();
      expect(status.notificationsEnabled, isFalse);
      expect(status.needsInAppNotice, isTrue);
    });
  });

  group('FlutterNotificationPermissionService', () {
    test('falls back gracefully when running outside mobile platform implementations', () async {
      final service = FlutterNotificationPermissionService();

      final status = await service.checkStatus();
      expect(status.notificationsEnabled, isTrue);
      expect(status.exactAlarmsAllowed, isTrue);
      expect(status.canDeliverReliably, isTrue);
      expect(status.needsInAppNotice, isFalse);

      final notifResult = await service.requestNotificationPermissions();
      expect(notifResult, isTrue);

      final alarmResult = await service.requestExactAlarmPermission();
      expect(alarmResult, isTrue);
    });
  });
}
