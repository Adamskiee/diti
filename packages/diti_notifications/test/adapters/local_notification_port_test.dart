import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_notifications/src/adapters/local_notification_port.dart';
import '../mocks/mock_notification_client.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
  });

  group('LocalNotificationPort', () {
    late MockNotificationClient mockClient;
    late LocalNotificationPort port;

    setUp(() {
      mockClient = MockNotificationClient();
      port = LocalNotificationPort(client: mockClient);

      when(() => mockClient.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async {});

      when(() => mockClient.cancel(any())).thenAnswer((_) async {});
    });

    test('scheduleBoundaryNotification calls client.zonedSchedule with exact mode', () async {
      final expectedUtc = DateTime.utc(2026, 10, 14, 11, 0, 0);

      await port.scheduleBoundaryNotification(
        runId: 'run-1',
        phaseId: 'p1',
        phaseName: 'Deep Focus',
        expectedUtc: expectedUtc,
      );

      verify(() => mockClient.zonedSchedule(
            id: any(named: 'id'),
            title: 'Phase Complete: Deep Focus',
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: UILocalNotificationDateInterpretation.absoluteTime,
            payload: any(named: 'payload'),
          )).called(1);

      expect(port.getScheduledIds('run-1'), isNotEmpty);
    });

    test('cancelBoundaries cancels all tracked notification IDs for run', () async {
      await port.scheduleBoundaryNotification(
        runId: 'run-1',
        phaseId: 'p1',
        phaseName: 'Focus',
        expectedUtc: DateTime.utc(2026, 10, 14, 11, 0, 0),
      );

      final ids = port.getScheduledIds('run-1');
      expect(ids.length, equals(1));
      final scheduledId = ids.first;

      await port.cancelBoundaries('run-1');

      verify(() => mockClient.cancel(scheduledId)).called(1);
      expect(port.getScheduledIds('run-1'), isEmpty);
    });

    test('cancelBoundaries swallows exceptions from client.cancel', () async {
      await port.scheduleBoundaryNotification(
        runId: 'run-1',
        phaseId: 'p1',
        phaseName: 'Focus',
        expectedUtc: DateTime.utc(2026, 10, 14, 11, 0, 0),
      );

      when(() => mockClient.cancel(any())).thenThrow(Exception('Platform cancel failed'));

      await expectLater(
        port.cancelBoundaries('run-1'),
        completes,
      );
      expect(port.getScheduledIds('run-1'), isEmpty);
    });

    test('scheduleRollingBoundaries calculates upcoming window and schedules sequentially', () async {
      const routine = Routine(
        id: 'r1',
        name: 'Pomodoro',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Work', durationMs: 1500000, transition: TransitionPolicy.auto),
          RoutinePhase(id: 'p2', name: 'Break', durationMs: 300000, transition: TransitionPolicy.auto),
        ],
      );
      final run = TimerRun(
        runId: 'run-pomodoro',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 14, 10, 0, 0),
        phaseStartedMonotonicMs: 0,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );

      await port.scheduleRollingBoundaries(
        run: run,
        currentUtc: DateTime.utc(2026, 10, 14, 10, 0, 0),
      );

      // p1 and p2 both scheduled
      verify(() => mockClient.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
          )).called(2);

      expect(port.getScheduledIds('run-pomodoro').length, equals(2));
    });

    test('scheduleRollingBoundaries uses inexact alarms when allowExactAlarms is false', () async {
      const routine = Routine(
        id: 'r1',
        name: 'Single',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Work', durationMs: 1500000, transition: TransitionPolicy.manual),
        ],
      );
      final run = TimerRun(
        runId: 'run-inexact',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 14, 10, 0, 0),
        phaseStartedMonotonicMs: 0,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );

      await port.scheduleRollingBoundaries(
        run: run,
        currentUtc: DateTime.utc(2026, 10, 14, 10, 0, 0),
        allowExactAlarms: false,
      );

      verify(() => mockClient.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('swallows platform exceptions without throwing', () async {
      when(() => mockClient.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            payload: any(named: 'payload'),
          )).thenThrow(Exception('Platform error: Exact alarms disabled'));

      // Should complete without rethrowing
      await expectLater(
        port.scheduleBoundaryNotification(
          runId: 'run-1',
          phaseId: 'p1',
          phaseName: 'Focus',
          expectedUtc: DateTime.utc(2026, 10, 14, 11, 0, 0),
        ),
        completes,
      );
    });
  });
}
