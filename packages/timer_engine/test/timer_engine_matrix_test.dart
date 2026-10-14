import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'fakes/in_memory_routine_repository.dart';
import 'fakes/in_memory_persistence_port.dart';
import 'fakes/in_memory_notification_port.dart';

void main() {
  group('Full Timer Engine Matrix Verification (T-001 – T-020)', () {
    test('barrel export exposes all required types and contracts', () {
      expect(RunStatus.values, isNotEmpty);
      expect(PhaseStatus.values, isNotEmpty);
      expect(TransitionPolicy.values, isNotEmpty);
      expect(RepeatMode.values, isNotEmpty);
      expect(TimerError.values, isNotEmpty);
      expect(TimerEventType.values, isNotEmpty);

      // Verify domain entity constructors
      final repeat = const RepeatRule(mode: RepeatMode.count, count: 2);
      final phase = const RoutinePhase(
        id: 'phase-1',
        name: 'Work',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
      );
      final routine = Routine(
        id: 'routine-1',
        name: 'Pomodoro',
        phases: [phase],
        repeatRule: repeat,
      );
      expect(routine.validate(), isNull);

      final state = TimerRunState(
        runId: 'run-1',
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhase: phase,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        remainingMs: 1500000,
        stateVersion: 1,
      );
      expect(state.runId, equals('run-1'));

      final run = TimerRun(
        runId: 'run-1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 1, 1),
        stateVersion: 1,
      );
      expect(run.runId, equals('run-1'));

      final event = TimerEvent(
        eventId: 'ev-1',
        runId: 'run-1',
        type: TimerEventType.runStarted,
        occurredAtUtc: DateTime.utc(2026, 1, 1),
      );
      expect(event.type, equals(TimerEventType.runStarted));

      final result = const TimerCommandResult(success: true, stateVersion: 1);
      expect(result.success, isTrue);

      // Verify clock types
      final clock = SystemClock();
      expect(clock.utcNow, isA<DateTime>());
      expect(clock.nowMs, isA<int>());

      // Verify exception type
      final ex = const PersistenceException('db error');
      expect(ex.message, equals('db error'));

      // Verify RecoveryManager and ReconciledState
      final recovery = RecoveryManager(wallClock: clock);
      expect(recovery.wallClock, equals(clock));
      final reconciled = ReconciledState(run: run, events: [event]);
      expect(reconciled.run, equals(run));
    });

    test('end-to-end integration: full lifecycle via public barrel API', () async {
      final clock = FakeClock();
      final routineRepo = InMemoryRoutineRepository();
      final persistence = InMemoryPersistencePort();
      final notifications = InMemoryNotificationPort();

      final routine = Routine(
        id: 'matrix-routine-1',
        name: 'Integration Routine',
        phases: const [
          RoutinePhase(
            id: 'phase-focus',
            name: 'Focus',
            durationMs: 30000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'phase-rest',
            name: 'Rest',
            durationMs: 10000,
            transition: TransitionPolicy.auto,
          ),
        ],
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      );
      await routineRepo.saveRoutine(routine);

      final TimerEngine engine = TimerEngineImpl(
        monotonicClock: clock,
        wallClock: clock,
        routineRepository: routineRepo,
        persistencePort: persistence,
        notificationPort: notifications,
      );

      final events = <TimerEvent>[];
      final states = <TimerRunState>[];
      engine.eventStream.listen(events.add);
      engine.stateStream.listen(states.add);

      // T-001: Start routine
      final startRes = await engine.start(routine.id);
      expect(startRes.success, isTrue);
      final runId = engine.activeRunId!;
      expect(engine.getState(runId)?.status, equals(RunStatus.running));
      expect(engine.getState(runId)?.currentPhaseIndex, equals(0));

      // Advance clock by 10s
      clock.advance(const Duration(seconds: 10));
      expect(engine.getState(runId)?.activeElapsedMs, equals(10000));
      expect(await engine.elapsed(runId), equals(const Duration(seconds: 10)));

      // T-003 & T-004: Pause & verify paused time exclusion
      final pauseRes = await engine.pause(runId);
      expect(pauseRes.success, isTrue);
      expect(engine.getState(runId)?.status, equals(RunStatus.paused));
      clock.advance(const Duration(seconds: 15));
      expect(engine.getState(runId)?.activeElapsedMs, equals(10000));

      // Resume
      final resumeRes = await engine.resume(runId);
      expect(resumeRes.success, isTrue);
      expect(engine.getState(runId)?.status, equals(RunStatus.running));

      // Advance remaining 20s to complete phase 0 (total 30s)
      clock.advance(const Duration(seconds: 20));
      await pumpEventQueue();
      expect(engine.getState(runId)?.currentPhaseIndex, equals(1));
      expect(engine.getState(runId)?.phaseStatus, equals(PhaseStatus.active));

      // Advance 10s to complete phase 1
      clock.advance(const Duration(seconds: 10));
      await pumpEventQueue();
      expect(engine.getState(runId)?.status, equals(RunStatus.completed));
      expect(events.any((e) => e.type == TimerEventType.runCompleted), isTrue);

      // Verify RecoveryManager via barrel export
      final recoveryManager = RecoveryManager(wallClock: clock);
      final savedRun = await persistence.getLatestActiveRun();
      expect(savedRun, isNotNull);
      final reconciledState = recoveryManager.reconcile(savedRun!, clock.nowMs);
      expect(reconciledState.run.status, equals(RunStatus.completed));

      engine.dispose();
    });
  });
}
