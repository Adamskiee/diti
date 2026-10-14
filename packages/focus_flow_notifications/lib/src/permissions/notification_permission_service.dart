import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPermissionStatus {
  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;

  const NotificationPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
  });

  bool get canDeliverReliably => notificationsEnabled && exactAlarmsAllowed;
  bool get needsInAppNotice => !canDeliverReliably;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPermissionStatus &&
          runtimeType == other.runtimeType &&
          notificationsEnabled == other.notificationsEnabled &&
          exactAlarmsAllowed == other.exactAlarmsAllowed;

  @override
  int get hashCode => Object.hash(notificationsEnabled, exactAlarmsAllowed);

  @override
  String toString() =>
      'NotificationPermissionStatus(notifications: $notificationsEnabled, exactAlarms: $exactAlarmsAllowed)';
}

abstract interface class NotificationPermissionService {
  Future<NotificationPermissionStatus> checkStatus();
  Future<bool> requestNotificationPermissions();
  Future<bool> requestExactAlarmPermission();
}

class FlutterNotificationPermissionService
    implements NotificationPermissionService {
  final FlutterLocalNotificationsPlugin _plugin;

  FlutterNotificationPermissionService(
      [FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<NotificationPermissionStatus> checkStatus() async {
    bool notificationsEnabled = true;
    bool exactAlarmsAllowed = true;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        notificationsEnabled =
            await androidPlugin.areNotificationsEnabled() ?? false;
        exactAlarmsAllowed =
            await androidPlugin.canScheduleExactNotifications() ?? false;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final options = await iosPlugin.checkPermissions();
        notificationsEnabled = options?.isEnabled ?? false;
        exactAlarmsAllowed = true;
      }
    } catch (_) {
      // Platform channel unavailable or uninitialized (e.g. desktop/test runner)
    }

    return NotificationPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );
  }

  @override
  Future<bool> requestNotificationPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          sound: true,
          badge: true,
        );
        return granted ?? false;
      }
    } catch (_) {
      // Platform channel unavailable or uninitialized
    }

    return true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestExactAlarmsPermission();
        return granted ?? false;
      }
    } catch (_) {
      // Platform channel unavailable or uninitialized
    }
    return true;
  }
}
