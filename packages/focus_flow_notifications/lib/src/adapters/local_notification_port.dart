import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timer_engine/timer_engine.dart';
import '../domain/boundary_window_calculator.dart';
import '../domain/scheduled_boundary.dart';
import '../ports/notification_client.dart';

class LocalNotificationPort implements NotificationPort {
  static const String channelId = 'focus_flow_phase_boundary';
  static const String channelName = 'Timer Phase Boundaries';
  static const String channelDescription = 'Alerts when a focus or break phase completes.';

  final NotificationClient _client;
  final BoundaryWindowCalculator _calculator;
  final Map<String, List<int>> _scheduledIdsByRun = {};

  LocalNotificationPort({
    required NotificationClient client,
    BoundaryWindowCalculator? calculator,
  })  : _client = client,
        _calculator = calculator ?? const BoundaryWindowCalculator();

  List<int> getScheduledIds(String runId) =>
      List.unmodifiable(_scheduledIdsByRun[runId] ?? const []);

  @override
  Future<void> scheduleBoundaryNotification({
    required String runId,
    required String phaseId,
    required String phaseName,
    required DateTime expectedUtc,
  }) async {
    final notificationId =
        BoundaryWindowCalculator.generateNotificationId(runId, 0, 0);

    final boundary = ScheduledBoundary(
      notificationId: notificationId,
      runId: runId,
      phaseIndex: 0,
      phaseId: phaseId,
      phaseName: phaseName,
      title: 'Phase Complete: $phaseName',
      body: 'Your phase has finished.',
      scheduledUtc: expectedUtc,
      requiresAction: false,
      isTerminal: false,
    );

    await _scheduleSingleBoundary(boundary, allowExactAlarms: true);
  }

  Future<void> scheduleRollingBoundaries({
    required TimerRun run,
    required DateTime currentUtc,
    bool allowExactAlarms = true,
  }) async {
    await cancelBoundaries(run.runId);

    final boundaries = _calculator.calculateUpcomingBoundaries(
      run: run,
      currentUtc: currentUtc,
    );

    for (final boundary in boundaries) {
      await _scheduleSingleBoundary(boundary, allowExactAlarms: allowExactAlarms);
    }
  }

  @override
  Future<void> cancelBoundaries(String runId) async {
    final ids = _scheduledIdsByRun.remove(runId);
    if (ids == null || ids.isEmpty) return;

    for (final id in ids) {
      try {
        await _client.cancel(id);
      } catch (_) {
        // Suppress platform errors on cancellation
      }
    }
  }

  Future<void> _scheduleSingleBoundary(
    ScheduledBoundary boundary, {
    required bool allowExactAlarms,
  }) async {
    final tzDate = tz.TZDateTime.from(boundary.scheduledUtc, tz.local);

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final payload = jsonEncode({
      'runId': boundary.runId,
      'phaseId': boundary.phaseId,
      'phaseName': boundary.phaseName,
      'requiresAction': boundary.requiresAction,
    });

    try {
      await _client.zonedSchedule(
        id: boundary.notificationId,
        title: boundary.title,
        body: boundary.body,
        scheduledDate: tzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: allowExactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      _scheduledIdsByRun
          .putIfAbsent(boundary.runId, () => <int>[])
          .add(boundary.notificationId);
    } catch (_) {
      // Suppress platform exceptions so core timer flow never breaks
    }
  }
}
