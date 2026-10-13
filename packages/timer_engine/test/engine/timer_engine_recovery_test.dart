import 'dart:async';
import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/engine/recovery_manager.dart';
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

  final multiPhaseRoutine = Routine(
    id: 'multi-routine',
    name: 'Multi Phase Routine',
    repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
    phases: const [
      RoutinePhase(id: 'work-1', name: 'Work 1', durationMs: 1500000, transition: TransitionPolicy.auto), // 25 min
      RoutinePhase(id: 'break-1', name: 'Break 1', durationMs: 300000, transition: TransitionPolicy.auto), // 5 min
      RoutinePhase(id: 'work-2', name: 'Work 2', durationMs: 1500000, transition: TransitionPolicy.manual), // 25 min manual
      RoutinePhase(id: 'break-2', name: 'Break 2', durationMs: 600000, transition: TransitionPolicy.auto),
    ],
  );

  setUp(() async {
    clock = FakeClock(initialUtc: DateTime.utc(2026, 10, 13, 10, 0, 0));
    routineRepo = InMemoryRoutineRepository();
    persistence = InMemoryPersistencePort();
    notifications = InMemoryNotificationPort();
    await routineRepo.saveRoutine(multiPhaseRoutine);

    engine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );
  });

  test('T-015: recover() invoked twice is strictly idempotent with no duplicated transitions or events', () async {
    await engine.start('multi-routine');

    engine.dispose();
    clock.advance(const Duration(minutes: 10));

    // Simulate crash and fresh engine boot
    final restoredEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await restoredEngine.recover();
    final firstRecoveryCount = persistence.committedEvents.length;

    await restoredEngine.recover();
    final secondRecoveryCount = persistence.committedEvents.length;

    expect(secondRecoveryCount, equals(firstRecoveryCount));
  });

  test('T-015: recover() invoked twice after multi-phase elapsed is strictly idempotent', () async {
    await engine.start('multi-routine');

    engine.dispose();
    // 25m work-1 + 5m break-1 = 30m. Advance 35m (5m into work-2)
    clock.advance(const Duration(minutes: 35));

    final restoredEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await restoredEngine.recover();
    final firstRecoveryCount = persistence.committedEvents.length;
    final firstStateVersion = persistence.activeRun!.stateVersion;

    await restoredEngine.recover();
    final secondRecoveryCount = persistence.committedEvents.length;
    final secondStateVersion = persistence.activeRun!.stateVersion;

    expect(secondRecoveryCount, equals(firstRecoveryCount));
    expect(secondStateVersion, equals(firstStateVersion));
  });

  test('T-017 & T-018: Backward wall clock and timezone shifts do not corrupt active elapsed calculation', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(minutes: 10));

    // Shift wall clock backward by 1 hour (NTP adjustment or timezone change)
    clock.setWallClock(DateTime.utc(2026, 10, 13, 9, 10, 0));

    final elapsed = await engine.elapsed(runId);
    expect(elapsed, equals(const Duration(minutes: 10)));
  });

  test('T-019: App suspended across multiple phases stops at manual phase barrier upon recovery', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m work-1 + 5m break-1 = 30m. Advance 40m (10m into work-2 which is manual)
    clock.advance(const Duration(minutes: 40));

    // Simulate new engine recovering persisted state
    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final state = freshEngine.getState(runId);

    // Reconciled past work-1 and break-1, now in work-2
    expect(state!.currentPhase.id, equals('work-2'));
    expect(state.currentPhaseIndex, equals(2));
    expect(state.activeElapsedMs, equals(600000)); // 10 min into work-2
  });

  test('T-019: Suspension past manual phase boundary transitions phase to awaitingAction', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m work-1 + 5m break-1 + 25m work-2 = 55m. Advance 65m (10m past manual boundary)
    clock.advance(const Duration(minutes: 65));

    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final state = freshEngine.getState(runId);

    expect(state!.currentPhase.id, equals('work-2'));
    expect(state.currentPhaseIndex, equals(2));
    expect(state.phaseStatus, equals(PhaseStatus.awaitingAction));
    expect(state.activeElapsedMs, equals(2100000)); // 35 min total in work-2
    expect(state.remainingMs, equals(0)); // clamped to 0
  });

  test('T-020: Multiple commands arriving concurrently execute sequentially in FIFO order', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    final results = await Future.wait([
      engine.pause(runId),
      engine.resume(runId),
      engine.skipPhase(runId),
    ]);

    expect(results.every((r) => r.success), isTrue);
    final state = engine.getState(runId);
    expect(state!.status, equals(RunStatus.running));
    expect(state.currentPhaseIndex, equals(1));
  });

  test('T-020: Concurrency flood executes strictly serialized in FIFO order', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    // Send a burst of 60 rapid interleaved pause/resume calls concurrently
    final futures = <Future>[];
    for (int i = 0; i < 30; i++) {
      futures.add(engine.pause(runId));
      futures.add(engine.resume(runId));
    }

    final results = await Future.wait(futures);
    expect(results.every((r) => r.success), isTrue);

    final state = engine.getState(runId);
    expect(state!.status, equals(RunStatus.running));
    // Starting version was 1; 60 commands executed and incremented stateVersion by 60 -> 61
    expect(state.stateVersion, equals(61));
  });

  test('Recovery restores paused run without advancing elapsed time', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    clock.advance(const Duration(minutes: 5));
    await engine.pause(runId);

    engine.dispose();
    // Advance 30 minutes while paused
    clock.advance(const Duration(minutes: 30));

    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final state = freshEngine.getState(runId);

    expect(state!.status, equals(RunStatus.paused));
    expect(state.activeElapsedMs, equals(300000)); // Still exactly 5 minutes
    expect(state.currentPhaseIndex, equals(0));
  });

  test('Recovery reconciles all phases and transitions run to completed if total duration elapsed', () async {
    await engine.start('multi-routine');

    // Complete routine has work-1 (25m auto), break-1 (5m auto), work-2 (25m manual), break-2 (10m auto)
    // Note: because work-2 is manual, suspension past work-2 stops at work-2 (manual barrier).
    // Let's create an all-auto routine to test full completion on recovery
    final allAutoRoutine = Routine(
      id: 'all-auto-routine',
      name: 'All Auto Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(id: 'p1', name: 'P1', durationMs: 60000, transition: TransitionPolicy.auto),
        RoutinePhase(id: 'p2', name: 'P2', durationMs: 60000, transition: TransitionPolicy.auto),
      ],
    );
    await routineRepo.saveRoutine(allAutoRoutine);

    final autoEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );
    await autoEngine.start('all-auto-routine');
    final autoRunId = autoEngine.activeRunId!;

    autoEngine.dispose();
    // Advance 3 minutes (180,000ms), exceeding 2 x 60,000ms = 120,000ms
    clock.advance(const Duration(minutes: 3));

    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final state = freshEngine.getState(autoRunId);

    expect(state!.status, equals(RunStatus.completed));
    expect(state.phaseStatus, equals(PhaseStatus.finished));
  });

  test('Recovery on open-ended phase accumulates wall-clock elapsed without advancing', () async {
    final openEndedRoutine = Routine(
      id: 'open-ended-routine',
      name: 'Open Ended Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(id: 'open', name: 'Open Phase', durationMs: null, transition: TransitionPolicy.manual),
      ],
    );
    await routineRepo.saveRoutine(openEndedRoutine);

    final openEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );
    await openEngine.start('open-ended-routine');
    final openRunId = openEngine.activeRunId!;

    openEngine.dispose();
    clock.advance(const Duration(minutes: 15));

    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final state = freshEngine.getState(openRunId);

    expect(state!.status, equals(RunStatus.running));
    expect(state.activeElapsedMs, equals(900000)); // 15 min
    expect(state.remainingMs, isNull);

    // Second recovery should be idempotent
    await freshEngine.recover();
    final secondState = freshEngine.getState(openRunId);
    expect(secondState!.activeElapsedMs, equals(900000));
  });

  test('Recovery after Pause -> Resume excludes paused duration and computes exact active elapsed time', () async {
    final longRoutine = Routine(
      id: 'long-routine',
      name: 'Long Routine',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
      phases: const [
        RoutinePhase(id: 'work-long', name: 'Work Long', durationMs: 1800000, transition: TransitionPolicy.auto), // 30 min
      ],
    );
    await routineRepo.saveRoutine(longRoutine);

    final testEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    // Start routine (10m active)
    await testEngine.start('long-routine');
    final runId = testEngine.activeRunId!;
    clock.advance(const Duration(minutes: 10));

    // Pause for 15m
    await testEngine.pause(runId);
    clock.advance(const Duration(minutes: 15));

    // Resume and run for 5m
    await testEngine.resume(runId);
    clock.advance(const Duration(minutes: 5));

    // Simulate app suspension / crash for 10m
    testEngine.dispose();
    clock.advance(const Duration(minutes: 10));

    // Create fresh engine and recover
    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final state = freshEngine.getState(runId);

    // Active elapsed time must be exactly 25m (10m + 5m + 10m), excluding 15m paused duration!
    expect(state!.activeElapsedMs, equals(1500000)); // 25 min = 1,500,000 ms
    expect(state.remainingMs, equals(300000)); // 30m - 25m = 5 min = 300,000 ms
    expect(state.status, equals(RunStatus.running));
  });

  test('Intra-phase recovery increments stateVersion when time elapses and preserves version on second call', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;
    final initialVersion = engine.getState(runId)!.stateVersion;

    engine.dispose();
    clock.advance(const Duration(minutes: 5));

    final freshEngine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );

    await freshEngine.recover();
    final recoveredState = freshEngine.getState(runId);
    expect(recoveredState!.stateVersion, equals(initialVersion + 1));
    expect(recoveredState.activeElapsedMs, equals(300000));

    // Second immediate recover with zero delta preserves stateVersion (idempotent)
    await freshEngine.recover();
    final secondRecoveredState = freshEngine.getState(runId);
    expect(secondRecoveredState!.stateVersion, equals(initialVersion + 1));
  });

  test('ReconciledState equality and hashCode', () async {
    await engine.start('multi-routine');
    final run = persistence.activeRun!;
    final state1 = ReconciledState(run: run, events: const []);
    final state2 = ReconciledState(run: run, events: const []);
    expect(state1, equals(state2));
    expect(state1.hashCode, equals(state2.hashCode));
  });
}
