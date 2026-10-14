import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:focus_flow_notifications/src/adapters/local_notification_port.dart';
import 'package:focus_flow_notifications/src/lifecycle/timer_lifecycle_coordinator.dart';

class MockTimerEngine extends Mock implements TimerEngine {}
class MockLocalNotificationPort extends Mock implements LocalNotificationPort {}
class MockWallClock extends Mock implements WallClock {}
class FakeTimerRun extends Fake implements TimerRun {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeTimerRun());
    registerFallbackValue(DateTime.utc(2026, 10, 14));
  });

  group('TimerLifecycleCoordinator', () {
    late MockTimerEngine mockEngine;
    late MockLocalNotificationPort mockPort;
    late MockWallClock mockClock;
    late TimerLifecycleCoordinator coordinator;

    setUp(() {
      mockEngine = MockTimerEngine();
      mockPort = MockLocalNotificationPort();
      mockClock = MockWallClock();

      when(() => mockEngine.recover()).thenAnswer((_) async {});
      when(() => mockClock.utcNow).thenReturn(DateTime.utc(2026, 10, 14, 12, 0, 0));

      coordinator = TimerLifecycleCoordinator(
        timerEngine: mockEngine,
        notificationPort: mockPort,
        wallClock: mockClock,
        attachLifecycleListener: false, // For unit test isolation
      );
    });

    test('initialize calls timerEngine.recover', () async {
      await coordinator.initialize();
      verify(() => mockEngine.recover()).called(1);
    });

    test('onResume invokes timerEngine.recover', () async {
      await coordinator.onResume();
      verify(() => mockEngine.recover()).called(1);
    });

    test('onPause pre-schedules rolling boundaries if run is running', () async {
      const routine = Routine(
        id: 'r1',
        name: 'Work',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 1500000, transition: TransitionPolicy.auto),
        ],
      );
      final run = TimerRun(
        runId: 'run-1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 14, 12, 0, 0),
        phaseStartedMonotonicMs: 0,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );

      when(() => mockEngine.activeRunId).thenReturn('run-1');
      when(() => mockEngine.getActiveRun()).thenReturn(run);
      when(() => mockPort.scheduleRollingBoundaries(
            run: any(named: 'run'),
            currentUtc: any(named: 'currentUtc'),
          )).thenAnswer((_) async {});

      await coordinator.onPause();

      verify(() => mockPort.scheduleRollingBoundaries(
            run: run,
            currentUtc: DateTime.utc(2026, 10, 14, 12, 0, 0),
          )).called(1);
    });

    test('onPause does not schedule if activeRunId is null', () async {
      when(() => mockEngine.activeRunId).thenReturn(null);
      await coordinator.onPause();
      verifyNever(() => mockPort.scheduleRollingBoundaries(
            run: any(named: 'run'),
            currentUtc: any(named: 'currentUtc'),
          ));
    });

    test('onPause does not schedule if activeRun is not running', () async {
      const routine = Routine(
        id: 'r1',
        name: 'Work',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 1500000, transition: TransitionPolicy.auto),
        ],
      );
      final run = TimerRun(
        runId: 'run-1',
        routineSnapshot: routine,
        status: RunStatus.paused,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 14, 12, 0, 0),
        phaseStartedMonotonicMs: 0,
        pausedAtUtc: DateTime.utc(2026, 10, 14, 12, 5, 0),
        stateVersion: 2,
        lastEventId: 'evt-2',
      );

      when(() => mockEngine.activeRunId).thenReturn('run-1');
      when(() => mockEngine.getActiveRun()).thenReturn(run);

      await coordinator.onPause();

      verifyNever(() => mockPort.scheduleRollingBoundaries(
            run: any(named: 'run'),
            currentUtc: any(named: 'currentUtc'),
          ));
    });

    test('dispose cleans up attached lifecycle listener', () {
      final coordinatorWithListener = TimerLifecycleCoordinator(
        timerEngine: mockEngine,
        notificationPort: mockPort,
        wallClock: mockClock,
        attachLifecycleListener: true,
      );

      expect(() => coordinatorWithListener.dispose(), returnsNormally);
      expect(() => coordinator.dispose(), returnsNormally);
    });
  });
}
