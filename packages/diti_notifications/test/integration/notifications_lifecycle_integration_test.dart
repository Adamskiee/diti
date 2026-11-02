import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_notifications/diti_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../mocks/mock_notification_client.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
  });

  group(
      'Phase 3 Integration: TimerEngine + Drift SQLite + Notifications + Lifecycle',
      () {
    late DitiDatabase database;
    late DriftRoutineRepository routineRepo;
    late DriftRunPersistencePort persistencePort;
    late MockNotificationClient mockClient;
    late LocalNotificationPort notificationPort;
    late FakeClock fakeClock;
    late TimerEngineImpl engine;
    late TimerLifecycleCoordinator coordinator;

    setUp(() async {
      database = DitiDatabase.connect(NativeDatabase.memory());
      routineRepo = DriftRoutineRepository(database);
      persistencePort = DriftRunPersistencePort(database);

      mockClient = MockNotificationClient();
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

      notificationPort = LocalNotificationPort(client: mockClient);
      fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 14, 9, 0, 0));

      engine = TimerEngineImpl(
        monotonicClock: fakeClock,
        wallClock: fakeClock,
        routineRepository: routineRepo,
        persistencePort: persistencePort,
        notificationPort: notificationPort,
      );

      coordinator = TimerLifecycleCoordinator(
        timerEngine: engine,
        notificationPort: notificationPort,
        wallClock: fakeClock,
        attachLifecycleListener: false,
      );
    });

    tearDown(() async {
      engine.dispose();
      coordinator.dispose();
      await database.close();
    });

    test('reconciles elapsed auto-phases after backgrounding and resume',
        () async {
      // 1. Save multi-phase routine: 15m Focus (auto) -> 5m Break (auto) -> 10m Review (manual)
      const routine = Routine(
        id: 'pomodoro-e2e',
        name: 'Pomodoro Workflow',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
              id: 'p1',
              name: 'Focus',
              durationMs: 900000,
              transition: TransitionPolicy.auto),
          RoutinePhase(
              id: 'p2',
              name: 'Break',
              durationMs: 300000,
              transition: TransitionPolicy.auto),
          RoutinePhase(
              id: 'p3',
              name: 'Review',
              durationMs: 600000,
              transition: TransitionPolicy.manual),
        ],
      );
      await routineRepo.saveRoutine(routine);

      // 2. Start timer
      final startRes = await engine.start('pomodoro-e2e');
      expect(startRes.success, isTrue);
      final runId = engine.activeRunId!;

      // 3. App goes to background
      await coordinator.onPause();
      // Should have scheduled rolling boundaries for p1, p2, p3
      expect(notificationPort.getScheduledIds(runId).length, equals(3));

      // 4. Simulate app backgrounded for 22 minutes (past p1: 15m and p2: 5m, into p3 at 2m)
      // Advance wall clock & monotonic time without running engine ticks
      fakeClock.advance(const Duration(minutes: 22));

      // 5. User opens app / taps notification -> onResume
      await coordinator.onResume();

      // 6. Verify reconciled state
      final state = engine.getState(runId);
      expect(state, isNotNull);
      expect(state!.currentPhaseIndex, equals(2)); // p3 (Review)
      expect(state.phaseName, equals('Review'));
      expect(state.phaseStatus, equals(PhaseStatus.active));
      expect(state.activeElapsedMs, equals(120000)); // 2 minutes into Review

      // 7. Verify SQLite persistence contains reconciled records
      final latestRun = await persistencePort.getLatestActiveRun();
      expect(latestRun, isNotNull);
      expect(latestRun!.currentPhaseIndex, equals(2));
    });
  });
}
