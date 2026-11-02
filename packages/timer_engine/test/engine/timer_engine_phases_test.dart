import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/timer_event.dart';
import 'package:timer_engine/src/domain/timer_run_state.dart';
import 'package:timer_engine/src/engine/timer_engine_impl.dart';
import '../fakes/fake_clock.dart';
import '../fakes/in_memory_notification_port.dart';
import '../fakes/in_memory_persistence_port.dart';
import '../fakes/in_memory_routine_repository.dart';

void main() {
  late FakeClock clock;
  late InMemoryRoutineRepository routineRepo;
  late InMemoryPersistencePort persistence;
  late InMemoryNotificationPort notifications;
  late TimerEngineImpl engine;

  setUp(() async {
    clock = FakeClock();
    routineRepo = InMemoryRoutineRepository();
    persistence = InMemoryPersistencePort();
    notifications = InMemoryNotificationPort();

    engine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );
  });

  test(
      'T-006: Auto phase reaches duration and advances to next phase exactly once',
      () async {
    final routine = Routine(
      id: 'auto-test',
      name: 'Auto Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 60000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'Break',
            durationMs: 30000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('auto-test');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(seconds: 60));
    await pumpEventQueue();

    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p2'));
    expect(state.currentPhaseIndex, equals(1));
    expect(state.phaseStatus, equals(PhaseStatus.active));
  });

  test(
      'Rest phase with manual transition reaches duration and runs negative remainingMs while awaiting user continuation',
      () async {
    final routine = Routine(
      id: 'rest-test',
      name: 'Rest Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
          id: 'p1',
          name: 'Short Break',
          durationMs: 30000,
          transition: TransitionPolicy.manual,
          kind: PhaseKind.rest,
        ),
        RoutinePhase(
          id: 'p2',
          name: 'Work',
          durationMs: 60000,
          transition: TransitionPolicy.auto,
          kind: PhaseKind.focus,
        ),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('rest-test');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(seconds: 40)); // 10s past 30s rest duration
    await pumpEventQueue();

    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p1')); // Still on p1 rest phase!
    expect(state.phaseStatus, equals(PhaseStatus.awaitingAction));
    expect(state.remainingMs, equals(-10000)); // -10 seconds
    expect(state.activeElapsedMs, equals(40000));

    // When the user continues, the phase advances and the ledger captures 40s
    await engine.finishPhase(runId);
    final advancedState = engine.getState(runId);
    expect(advancedState!.currentPhase.id, equals('p2'));
    expect(advancedState.completedPhases.first.durationMs, equals(40000));
  });

  test(
      'T-007: Manual phase reaches duration, transitions to awaitingAction without auto-advance',
      () async {
    final routine = Routine(
      id: 'manual-test',
      name: 'Manual Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Reading',
            durationMs: 60000,
            transition: TransitionPolicy.manual),
        RoutinePhase(
            id: 'p2',
            name: 'Notes',
            durationMs: 30000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('manual-test');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(seconds: 70)); // 10s past configured duration
    await pumpEventQueue();

    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p1')); // Still on p1!
    expect(state.phaseStatus, equals(PhaseStatus.awaitingAction));
    expect(state.status, equals(RunStatus.running));
    expect(state.remainingMs, equals(0));
    expect(state.activeElapsedMs, equals(70000)); // Elapsed continues counting
  });

  test(
      'T-008: Open-ended phase runs and active elapsed increases without countdown boundary',
      () async {
    final routine = Routine(
      id: 'flow-test',
      name: 'Flow Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'flow',
            name: 'Deep Flow',
            durationMs: null,
            transition: TransitionPolicy.manual),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('flow-test');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(minutes: 45));
    await pumpEventQueue();

    final state = engine.getState(runId);
    expect(state!.activeElapsedMs, equals(2700000));
    expect(state.remainingMs, isNull);
    expect(state.phaseStatus, equals(PhaseStatus.active));
  });

  test(
      'T-009 & T-010: Skip final phase and repeat count is reached completes routine',
      () async {
    final events = <TimerEvent>[];
    final eventSub = engine.eventStream.listen(events.add);

    final routine = Routine(
      id: 'repeat-count',
      name: 'Count Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 60000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('repeat-count');
    final runId = engine.activeRunId!;

    // Pass first repeat
    await engine.skipPhase(runId);
    var state = engine.getState(runId);
    expect(state!.repeatIndex, equals(1));
    expect(state.status, equals(RunStatus.running));
    expect(state.phaseStatus, equals(PhaseStatus.active));

    // Pass second (final) repeat
    await engine.skipPhase(runId);
    await pumpEventQueue();
    state = engine.getState(runId);
    expect(state!.status, equals(RunStatus.completed));
    expect(state.phaseStatus, equals(PhaseStatus.skipped));
    // Both phases were skipped without running, so the run has no active
    // time at all: the old expectation of the configured 60s phase length
    // counted a phase that never ran.
    expect(state.totalActiveElapsedMs, equals(0));

    // Verifies both phaseSkipped and runCompleted events are emitted
    expect(events.any((e) => e.type == TimerEventType.phaseSkipped), isTrue);
    expect(events.any((e) => e.type == TimerEventType.runCompleted), isTrue);

    await eventSub.cancel();
  });

  test(
      'T-011: Forever repeat continues loop until explicitly stopped or finished',
      () async {
    final routine = Routine(
      id: 'forever-routine',
      name: 'Infinite Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.forever),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('forever-routine');
    final runId = engine.activeRunId!;

    // Advance 5 cycles
    for (int i = 0; i < 5; i++) {
      clock.advance(const Duration(seconds: 10));
      await pumpEventQueue();
    }

    final state = engine.getState(runId);
    expect(state!.repeatIndex, equals(5));
    expect(state.status, equals(RunStatus.running));

    await engine.finishRun(runId);
    final finalState = engine.getState(runId);
    expect(finalState!.status, equals(RunStatus.completed));
    expect(finalState.phaseStatus, equals(PhaseStatus.finished));
  });

  test(
      'T-012: Duplicate transition callback does not produce duplicate phase transitions',
      () async {
    final routine = Routine(
      id: 'duplicate-test',
      name: 'Dup Test',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'P2',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('duplicate-test');
    final runId = engine.activeRunId!;

    // Manually trigger boundary reach with stale version
    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();
    final initialVersion = engine.getState(runId)!.stateVersion;

    // Advance again without reaching next boundary
    clock.advance(const Duration(seconds: 1));
    await pumpEventQueue();
    expect(engine.getState(runId)!.stateVersion, equals(initialVersion));
  });

  test('finishPhase advances phase and emits phaseFinished event', () async {
    final events = <TimerEvent>[];
    final eventSub = engine.eventStream.listen(events.add);

    final routine = Routine(
      id: 'finish-phase-test',
      name: 'Finish Phase Test',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Phase 1',
            durationMs: 60000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'Phase 2',
            durationMs: 30000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('finish-phase-test');
    final runId = engine.activeRunId!;

    final res = await engine.finishPhase(runId);
    expect(res.success, isTrue);

    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p2'));
    expect(state.currentPhaseIndex, equals(1));
    expect(events.any((e) => e.type == TimerEventType.phaseFinished), isTrue);

    await eventSub.cancel();
  });

  test(
      'finishPhase on manual awaitingAction phase resumes active on next phase',
      () async {
    final routine = Routine(
      id: 'manual-finish-test',
      name: 'Manual Finish Test',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Reading',
            durationMs: 10000,
            transition: TransitionPolicy.manual),
        RoutinePhase(
            id: 'p2',
            name: 'Writing',
            durationMs: 20000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('manual-finish-test');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();
    expect(engine.getState(runId)!.phaseStatus,
        equals(PhaseStatus.awaitingAction));

    final res = await engine.finishPhase(runId);
    expect(res.success, isTrue);

    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p2'));
    expect(state.phaseStatus, equals(PhaseStatus.active));
  });

  test('skipPhase while paused transitions to active running next phase',
      () async {
    final routine = Routine(
      id: 'skip-paused-test',
      name: 'Skip Paused Test',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 60000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'Rest',
            durationMs: 30000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('skip-paused-test');
    final runId = engine.activeRunId!;

    await engine.pause(runId);
    expect(engine.getState(runId)!.status, equals(RunStatus.paused));

    final skipRes = await engine.skipPhase(runId);
    expect(skipRes.success, isTrue);

    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p2'));
    expect(state.status, equals(RunStatus.running));
    expect(state.phaseStatus, equals(PhaseStatus.active));
  });

  test('finishRun transitions to completed and cancels boundaries', () async {
    final routine = Routine(
      id: 'finish-run-test',
      name: 'Finish Run Test',
      repeatRule: const RepeatRule(mode: RepeatMode.forever),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 60000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('finish-run-test');
    final runId = engine.activeRunId!;
    expect(notifications.scheduledBoundaries, hasLength(1));

    clock.advance(const Duration(seconds: 25));

    final res = await engine.finishRun(runId);
    expect(res.success, isTrue);

    final state = engine.getState(runId);
    expect(state!.status, equals(RunStatus.completed));
    expect(state.phaseStatus, equals(PhaseStatus.finished));
    // The finished phase's 25s live in the ledger now, so the run total
    // carries them and the phase that is over carries none.
    expect(state.totalActiveElapsedMs, equals(25000));
    expect(notifications.scheduledBoundaries, isEmpty);

    // finishRun on already completed is idempotent
    final res2 = await engine.finishRun(runId);
    expect(res2.success, isTrue);
  });

  test('Commands return invalidTransition or runNotFound when expected',
      () async {
    final resSkip = await engine.skipPhase('non-existent');
    expect(resSkip.success, isFalse);
    expect(resSkip.error, equals(TimerError.runNotFound));

    final resFinishPhase = await engine.finishPhase('non-existent');
    expect(resFinishPhase.success, isFalse);
    expect(resFinishPhase.error, equals(TimerError.runNotFound));

    final resFinishRun = await engine.finishRun('non-existent');
    expect(resFinishRun.success, isFalse);
    expect(resFinishRun.error, equals(TimerError.runNotFound));

    final routine = Routine(
      id: 'cmd-err-test',
      name: 'Err Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);
    await engine.start('cmd-err-test');
    final runId = engine.activeRunId!;
    await engine.stop(runId);

    final resSkipAfterStop = await engine.skipPhase(runId);
    expect(resSkipAfterStop.success, isFalse);
    expect(resSkipAfterStop.error, equals(TimerError.invalidTransition));

    final resFinishPhaseAfterStop = await engine.finishPhase(runId);
    expect(resFinishPhaseAfterStop.success, isFalse);
    expect(resFinishPhaseAfterStop.error, equals(TimerError.invalidTransition));

    final resFinishRunAfterStop = await engine.finishRun(runId);
    expect(resFinishRunAfterStop.success, isFalse);
    expect(resFinishRunAfterStop.error, equals(TimerError.invalidTransition));
  });

  test('Multi-phase routine with repeat count cycles correctly', () async {
    final routine = Routine(
      id: 'multi-phase-repeat',
      name: 'Multi Phase Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'P2',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('multi-phase-repeat');
    final runId = engine.activeRunId!;

    // Cycle 0, P1 -> P2
    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();
    var state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p2'));
    expect(state.repeatIndex, equals(0));

    // Cycle 0, P2 -> Cycle 1, P1
    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();
    state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p1'));
    expect(state.repeatIndex, equals(1));

    // Cycle 1, P1 -> P2
    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();
    state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p2'));
    expect(state.repeatIndex, equals(1));

    // Cycle 1, P2 completes routine
    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();
    state = engine.getState(runId);
    expect(state!.status, equals(RunStatus.completed));
    expect(state.currentPhase.id, equals('p2'));
    expect(state.phaseStatus, equals(PhaseStatus.finished));
    // Four phases of 10s each: the run total is the sum of the ledger.
    expect(state.totalActiveElapsedMs, equals(40000));
  });

  test(
      'Completing final phase emits both phaseFinished and runCompleted events',
      () async {
    final events = <TimerEvent>[];
    final eventSub = engine.eventStream.listen(events.add);

    final routine = Routine(
      id: 'events-complete-test',
      name: 'Events Complete Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('events-complete-test');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();

    final state = engine.getState(runId);
    expect(state!.status, equals(RunStatus.completed));
    expect(state.phaseStatus, equals(PhaseStatus.finished));

    expect(events.length, equals(3)); // runStarted, phaseFinished, runCompleted
    expect(events[0].type, equals(TimerEventType.runStarted));
    expect(events[1].type, equals(TimerEventType.phaseFinished));
    expect(events[2].type, equals(TimerEventType.runCompleted));

    await eventSub.cancel();
  });

  test(
      'Persistence failure on skipPhase, finishPhase, or finishRun surfaces error and rolls back without dirty emission',
      () async {
    final emittedStates = <TimerRunState>[];
    final stateSub = engine.stateStream.listen(emittedStates.add);

    final routine = Routine(
      id: 'persist-fail-test',
      name: 'Persist Fail',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 60000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'P2',
            durationMs: 30000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('persist-fail-test');
    final runId = engine.activeRunId!;
    final statesAfterStart = emittedStates.length;

    persistence.shouldFail = true;

    final skipRes = await engine.skipPhase(runId);
    expect(skipRes.success, isFalse);
    expect(skipRes.error, equals(TimerError.persistenceFailure));
    expect(engine.getState(runId)!.currentPhase.id, equals('p1'));
    // No new state emitted on failure
    expect(emittedStates.length, equals(statesAfterStart));

    final finishPhaseRes = await engine.finishPhase(runId);
    expect(finishPhaseRes.success, isFalse);
    expect(finishPhaseRes.error, equals(TimerError.persistenceFailure));
    expect(engine.getState(runId)!.currentPhase.id, equals('p1'));
    expect(emittedStates.length, equals(statesAfterStart));

    final finishRunRes = await engine.finishRun(runId);
    expect(finishRunRes.success, isFalse);
    expect(finishRunRes.error, equals(TimerError.persistenceFailure));
    expect(engine.getState(runId)!.status, equals(RunStatus.running));
    expect(emittedStates.length, equals(statesAfterStart));

    await stateSub.cancel();
  });

  test(
      'Persistence failure during auto boundary callback preserves active run without dirty mutation',
      () async {
    final emittedStates = <TimerRunState>[];
    final stateSub = engine.stateStream.listen(emittedStates.add);

    final routine = Routine(
      id: 'persist-fail-boundary',
      name: 'Persist Fail Boundary',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
        RoutinePhase(
            id: 'p2',
            name: 'P2',
            durationMs: 10000,
            transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(routine);

    await engine.start('persist-fail-boundary');
    final runId = engine.activeRunId!;
    final statesAfterStart = emittedStates.length;

    persistence.shouldFail = true;

    clock.advance(const Duration(seconds: 10));
    await pumpEventQueue();

    // In-memory state remains on p1 and version is unchanged because write failed
    final state = engine.getState(runId);
    expect(state!.currentPhase.id, equals('p1'));
    expect(state.stateVersion, equals(1));
    expect(emittedStates.length, equals(statesAfterStart));

    await stateSub.cancel();
  });
}
