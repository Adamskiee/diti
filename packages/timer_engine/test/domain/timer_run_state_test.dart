import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/timer_run.dart';
import 'package:timer_engine/src/domain/timer_run_state.dart';

void main() {
  group('TimerRun & Elapsed Time Calculations', () {
    final routine = Routine(
      id: 'routine-1',
      name: 'Test Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
      phases: const [
        RoutinePhase(
          id: 'p1',
          name: 'Work',
          durationMs: 1500000,
          transition: TransitionPolicy.auto,
        ),
        RoutinePhase(
          id: 'p2',
          name: 'Flow',
          durationMs: null,
          transition: TransitionPolicy.manual,
        ),
      ],
    );

    test('calculates active elapsed and remaining correctly for running timed phase', () {
      final run = TimerRun(
        runId: 'test-run-1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 10000, // 10s previously accumulated
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 50000,
        stateVersion: 1,
      );

      // Current monotonic time is 70000 (20s elapsed in active segment)
      final state = run.calculateState(currentMonotonicMs: 70000);

      expect(state.runId, equals('test-run-1'));
      expect(state.status, equals(RunStatus.running));
      expect(state.phaseStatus, equals(PhaseStatus.active));
      expect(state.currentPhase, equals(routine.phases[0]));
      expect(state.currentPhaseIndex, equals(0));
      expect(state.repeatIndex, equals(0));
      expect(state.currentRepetition, equals(1));
      expect(state.activeElapsedMs, equals(30000)); // 10s + 20s = 30s
      expect(state.remainingMs, equals(1470000)); // 1500s - 30s = 1470s
      expect(state.stateVersion, equals(1));
    });

    test('paused run freezes elapsed time', () {
      final run = TimerRun(
        runId: 'test-run-2',
        routineSnapshot: routine,
        status: RunStatus.paused,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 30000, // frozen at 30s
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: null,
        pausedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 30),
        stateVersion: 2,
      );

      final state = run.calculateState(currentMonotonicMs: 999999);
      expect(state.activeElapsedMs, equals(30000));
      expect(state.remainingMs, equals(1470000));
      expect(state.status, equals(RunStatus.paused));
    });

    test('open-ended phase has null remainingMs and displays active elapsed', () {
      final run = TimerRun(
        runId: 'test-run-3',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 1, // Phase 2 (open ended)
        repeatIndex: 1,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 1000,
        stateVersion: 1,
      );

      final state = run.calculateState(currentMonotonicMs: 25000);
      expect(state.activeElapsedMs, equals(24000));
      expect(state.remainingMs, isNull);
      expect(state.currentRepetition, equals(2));
    });

    test('clamps remaining to 0 when activeElapsed exceeds phase durationMs', () {
      final run = TimerRun(
        runId: 'test-run-overtime',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0, // duration 1500000
        repeatIndex: 0,
        accumulatedMs: 1500000,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 1000,
        stateVersion: 1,
      );

      // Monotonic advanced by 5000ms -> activeMs = 1505000
      final state = run.calculateState(currentMonotonicMs: 6000);
      expect(state.activeElapsedMs, equals(1505000));
      expect(state.remainingMs, equals(0));
    });

    test('protects against monotonic clock skew backwards (delta < 0 clamped to 0)', () {
      final run = TimerRun(
        runId: 'test-run-skew',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 5000,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 10000,
        stateVersion: 1,
      );

      // current monotonic is reported before start monotonic
      final state = run.calculateState(currentMonotonicMs: 8000);
      expect(state.activeElapsedMs, equals(5000));
      expect(state.remainingMs, equals(1495000));
    });

    test('currentPhase getter returns phase at currentPhaseIndex', () {
      final run0 = TimerRun(
        runId: 'r0',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        stateVersion: 1,
      );
      expect(run0.currentPhase.id, equals('p1'));

      final run1 = run0.copyWith(currentPhaseIndex: 1);
      expect(run1.currentPhase.id, equals('p2'));
    });

    test('TimerRun copyWith updates fields and supports setting null via callbacks', () {
      final initial = TimerRun(
        runId: 'run-orig',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 5000,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 20000,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );

      final nowUtc = DateTime.utc(2026, 10, 13, 10, 5, 0);
      final paused = initial.copyWith(
        status: RunStatus.paused,
        accumulatedMs: 10000,
        phaseStartedMonotonicMs: () => null,
        pausedAtUtc: () => nowUtc,
        stateVersion: 2,
        lastEventId: () => 'evt-2',
      );

      expect(paused.runId, equals('run-orig'));
      expect(paused.status, equals(RunStatus.paused));
      expect(paused.accumulatedMs, equals(10000));
      expect(paused.phaseStartedMonotonicMs, isNull);
      expect(paused.pausedAtUtc, equals(nowUtc));
      expect(paused.stateVersion, equals(2));
      expect(paused.lastEventId, equals('evt-2'));

      // Resuming and resetting pausedAtUtc to null
      final resumed = paused.copyWith(
        status: RunStatus.running,
        phaseStartedMonotonicMs: () => 50000,
        pausedAtUtc: () => null,
        stateVersion: 3,
      );
      expect(resumed.status, equals(RunStatus.running));
      expect(resumed.phaseStartedMonotonicMs, equals(50000));
      expect(resumed.pausedAtUtc, isNull);
      expect(resumed.lastEventId, equals('evt-2'));
    });

    test('TimerRun equality and hashCode', () {
      final run1 = TimerRun(
        runId: 'r1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 100,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 500,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );

      final run2 = TimerRun(
        runId: 'r1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 100,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
        phaseStartedMonotonicMs: 500,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );

      final runDiff = run1.copyWith(accumulatedMs: 200);

      expect(run1, equals(run2));
      expect(run1.hashCode, equals(run2.hashCode));
      expect(run1, isNot(equals(runDiff)));
    });

    test('TimerRun normalizes non-UTC DateTime inputs to UTC', () {
      final localStart = DateTime(2026, 10, 13, 10, 0, 0);
      final localPause = DateTime(2026, 10, 13, 10, 1, 0);

      final run = TimerRun(
        runId: 'r-tz',
        routineSnapshot: routine,
        status: RunStatus.paused,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: localStart,
        pausedAtUtc: localPause,
        stateVersion: 1,
      );

      expect(run.phaseStartedAtUtc.isUtc, isTrue);
      expect(run.phaseStartedAtUtc, equals(localStart.toUtc()));
      expect(run.pausedAtUtc?.isUtc, isTrue);
      expect(run.pausedAtUtc, equals(localPause.toUtc()));
    });

    test('TimerRunState equality and hashCode', () {
      final state1 = TimerRunState(
        runId: 'r1',
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhase: routine.phases[0],
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 1000,
        remainingMs: 5000,
        stateVersion: 1,
      );

      final state2 = TimerRunState(
        runId: 'r1',
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhase: routine.phases[0],
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 1000,
        remainingMs: 5000,
        stateVersion: 1,
      );

      final stateDiff = state1.copyWith(activeElapsedMs: 2000);

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(stateDiff)));
    });
  });
}
