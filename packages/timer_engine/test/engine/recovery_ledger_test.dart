import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
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

  /// work-1 25m auto, break-1 5m auto, work-2 25m manual, break-2 10m auto.
  final multiPhaseRoutine = Routine(
    id: 'multi-routine',
    name: 'Multi Phase Routine',
    repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
    phases: const [
      RoutinePhase(
        id: 'work-1',
        name: 'Work 1',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.focus,
      ),
      RoutinePhase(
        id: 'break-1',
        name: 'Break 1',
        durationMs: 300000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      ),
      RoutinePhase(
        id: 'work-2',
        name: 'Work 2',
        durationMs: 1500000,
        transition: TransitionPolicy.manual,
        kind: PhaseKind.focus,
      ),
      RoutinePhase(
        id: 'break-2',
        name: 'Break 2',
        durationMs: 600000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      ),
    ],
  );

  /// Three auto phases, so a recovery can cross one of them and a later
  /// recovery can cross the next one.
  final allAutoRoutine = Routine(
    id: 'all-auto-routine',
    name: 'All Auto Routine',
    repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
    phases: const [
      RoutinePhase(
        id: 'p1',
        name: 'P1',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.focus,
      ),
      RoutinePhase(
        id: 'p2',
        name: 'P2',
        durationMs: 300000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      ),
      RoutinePhase(
        id: 'p3',
        name: 'P3',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.focus,
      ),
    ],
  );

  /// A forever-repeating routine, so a recovery can cross the same phase
  /// twice.
  final foreverRoutine = Routine(
    id: 'forever-routine',
    name: 'Forever Routine',
    repeatRule: const RepeatRule(mode: RepeatMode.forever),
    phases: const [
      RoutinePhase(
        id: 'p1',
        name: 'P1',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.focus,
      ),
      RoutinePhase(
        id: 'p2',
        name: 'P2',
        durationMs: 300000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      ),
    ],
  );

  setUp(() async {
    clock = FakeClock(initialUtc: DateTime.utc(2026, 10, 13, 10, 0, 0));
    routineRepo = InMemoryRoutineRepository();
    persistence = InMemoryPersistencePort();
    notifications = InMemoryNotificationPort();
    await routineRepo.saveRoutine(multiPhaseRoutine);
    await routineRepo.saveRoutine(allAutoRoutine);
    await routineRepo.saveRoutine(foreverRoutine);

    engine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );
  });

  /// A fresh engine that reads the same persisted run, as if the app had
  /// been killed and restarted.
  TimerEngineImpl freshEngine() => TimerEngineImpl(
        monotonicClock: clock,
        wallClock: clock,
        routineRepository: routineRepo,
        persistencePort: persistence,
        notificationPort: notifications,
      );

  test('recovery appends an entry for every auto phase it crossed', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m work-1 + 5m break-1 = 30m, then 5m into work-2.
    clock.advance(const Duration(minutes: 35));

    final recovered = freshEngine();
    await recovered.recover();

    final state = recovered.getState(runId)!;
    expect(state.completedPhases, hasLength(2));

    final work = state.completedPhases[0];
    expect(work.phaseId, equals('work-1'));
    expect(work.phaseName, equals('Work 1'));
    expect(work.kind, equals(PhaseKind.focus));
    expect(work.phaseIndex, equals(0));
    expect(work.repeatIndex, equals(0));
    expect(work.durationMs, equals(1500000));
    expect(work.outcome, equals(PhaseStatus.finished));

    final rest = state.completedPhases[1];
    expect(rest.phaseId, equals('break-1'));
    expect(rest.phaseName, equals('Break 1'));
    expect(rest.kind, equals(PhaseKind.rest));
    expect(rest.phaseIndex, equals(1));
    expect(rest.repeatIndex, equals(0));
    expect(rest.durationMs, equals(300000));
    expect(rest.outcome, equals(PhaseStatus.finished));

    // The run's total is the ledger plus the phase that is running now.
    expect(state.totalActiveElapsedMs, equals(1500000 + 300000 + 300000));
  });

  test('recovery is idempotent — reconciling twice appends nothing', () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    clock.advance(const Duration(minutes: 35));

    final recovered = freshEngine();
    await recovered.recover();
    final first = recovered.getState(runId)!;
    expect(first.completedPhases, hasLength(2));

    // The same engine recovers the run it has just reconciled.
    await recovered.recover();
    final second = recovered.getState(runId)!;
    expect(second.completedPhases, hasLength(2));
    expect(second.completedPhases, equals(first.completedPhases));
    expect(second.totalActiveElapsedMs, equals(first.totalActiveElapsedMs));

    // A fresh engine recovers the already reconciled run.
    final rebooted = freshEngine();
    await rebooted.recover();
    final third = rebooted.getState(runId)!;
    expect(third.completedPhases, hasLength(2));
    expect(third.completedPhases, equals(first.completedPhases));
    expect(third.totalActiveElapsedMs, equals(first.totalActiveElapsedMs));
  });

  test('recovery keeps a manual phase active until its duration is reached',
      () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m work-1 + 5m break-1 = 30m, then 5m into work-2 (manual).
    clock.advance(const Duration(minutes: 35));

    final recovered = freshEngine();
    await recovered.recover();

    final state = recovered.getState(runId)!;
    expect(state.completedPhases, hasLength(2));
    // The run does not advance past the manual phase.
    expect(state.currentPhase.id, equals('work-2'));
    expect(state.currentPhaseIndex, equals(2));
    // The manual phase keeps the 5 minutes it ran.
    expect(state.activeElapsedMs, equals(300000));
    expect(state.phaseStatus, equals(PhaseStatus.active));
  });

  test('recovery stops at a manual phase that has reached its duration',
      () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m work-1 + 5m break-1 = 30m, then 35m into work-2 (manual, 25m).
    clock.advance(const Duration(minutes: 65));

    final recovered = freshEngine();
    await recovered.recover();

    final state = recovered.getState(runId)!;
    // The manual phase never ended, so it has no ledger entry.
    expect(state.completedPhases, hasLength(2));
    expect(state.currentPhase.id, equals('work-2'));
    expect(state.phaseStatus, equals(PhaseStatus.awaitingAction));
    // The partial time of the manual phase stays in the accumulator.
    expect(state.activeElapsedMs, equals(2100000));
    expect(state.totalActiveElapsedMs, equals(1500000 + 300000 + 2100000));
  });

  test(
      'recovered entries are ordered and their timestamps never exceed the recovery time',
      () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;
    final startedAt = clock.utcNow;

    engine.dispose();
    clock.advance(const Duration(minutes: 35));
    final recoveryUtc = clock.utcNow;

    final recovered = freshEngine();
    await recovered.recover();

    final entries = recovered.getState(runId)!.completedPhases;
    expect(entries, hasLength(2));

    // The reconstruction starts at the phase that was running when the app died.
    expect(entries.first.startedAtUtc, equals(startedAt));

    for (final entry in entries) {
      expect(entry.endedAtUtc.isAfter(recoveryUtc), isFalse);
      expect(entry.startedAtUtc.isAfter(entry.endedAtUtc), isFalse);
    }

    // Each phase starts where the one before it ended.
    for (var i = 1; i < entries.length; i++) {
      expect(entries[i].startedAtUtc, equals(entries[i - 1].endedAtUtc));
    }

    // The reconstruction ends where the phase that is running now began.
    expect(entries.last.endedAtUtc,
        equals(startedAt.add(const Duration(minutes: 30))));
  });

  test('a run killed inside its first phase records nothing and keeps its time',
      () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    clock.advance(const Duration(minutes: 10));

    final recovered = freshEngine();
    await recovered.recover();

    final state = recovered.getState(runId)!;
    expect(state.completedPhases, isEmpty);
    expect(state.currentPhaseIndex, equals(0));
    expect(state.activeElapsedMs, equals(600000));
    expect(state.totalActiveElapsedMs, equals(600000));
  });

  test('a run that finished its whole routine while dead records every phase',
      () async {
    await engine.start('all-auto-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m p1 + 5m p2 + 25m p3 = 55m, the whole routine.
    clock.advance(const Duration(minutes: 60));

    final recovered = freshEngine();
    await recovered.recover();

    final state = recovered.getState(runId)!;
    expect(state.status, equals(RunStatus.completed));
    expect(state.completedPhases, hasLength(3));
    expect(
      state.completedPhases.map((entry) => entry.phaseId).toList(),
      equals(['p1', 'p2', 'p3']),
    );
    expect(
      state.completedPhases.map((entry) => entry.durationMs).toList(),
      equals([1500000, 300000, 1500000]),
    );
    // The ended run keeps its time in the ledger, not in the accumulator.
    expect(state.totalActiveElapsedMs, equals(3300000));
    expect(persistence.activeRun!.accumulatedMs, equals(0));
  });

  test('a second recovery appends only the phases crossed since the first',
      () async {
    await engine.start('all-auto-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // 25m p1 + 5m p2 = 30m, then 5m into p3.
    clock.advance(const Duration(minutes: 35));

    final recovered = freshEngine();
    await recovered.recover();
    expect(recovered.getState(runId)!.completedPhases, hasLength(2));

    // The app dies again, later, with p3 nearly over.
    recovered.dispose();
    clock.advance(const Duration(minutes: 25));

    final rebooted = freshEngine();
    await rebooted.recover();

    final state = rebooted.getState(runId)!;
    expect(state.status, equals(RunStatus.completed));
    expect(state.completedPhases, hasLength(3));
    expect(
      state.completedPhases.map((entry) => entry.phaseId).toList(),
      equals(['p1', 'p2', 'p3']),
    );
    expect(
      state.completedPhases.map((entry) => entry.phaseIndex).toList(),
      equals([0, 1, 2]),
    );
    // The ledger is contiguous across the two crashes: the phase the second
    // recovery crossed starts where the first recovery's last entry ended.
    for (var i = 1; i < state.completedPhases.length; i++) {
      expect(
        state.completedPhases[i].startedAtUtc,
        equals(state.completedPhases[i - 1].endedAtUtc),
      );
    }
  });

  test('a forever-repeating routine records one entry per phase occurrence',
      () async {
    await engine.start('forever-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    // Two whole cycles of 30 minutes, then 5 minutes into the third p1.
    clock.advance(const Duration(minutes: 65));

    final recovered = freshEngine();
    await recovered.recover();

    final state = recovered.getState(runId)!;
    expect(state.completedPhases, hasLength(4));
    expect(
      state.completedPhases.map((entry) => entry.phaseId).toList(),
      equals(['p1', 'p2', 'p1', 'p2']),
    );
    expect(
      state.completedPhases.map((entry) => entry.phaseIndex).toList(),
      equals([0, 1, 0, 1]),
    );
    expect(
      state.completedPhases.map((entry) => entry.repeatIndex).toList(),
      equals([0, 0, 1, 1]),
    );
    expect(state.currentPhaseIndex, equals(0));
    expect(state.repeatIndex, equals(2));
    expect(state.activeElapsedMs, equals(300000));
  });

  test('the recovered ledger and the live entries add up to the run time',
      () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;
    final startedAt = clock.utcNow;

    engine.dispose();
    clock.advance(const Duration(minutes: 35));

    final recovered = freshEngine();
    await recovered.recover();
    expect(recovered.getState(runId)!.completedPhases, hasLength(2));

    // The app runs on: work-2 has 20 minutes left, then the user ends it.
    clock.advance(const Duration(minutes: 20));
    await pumpEventQueue();
    final result = await recovered.finishPhase(runId);
    expect(result.success, isTrue);

    final state = recovered.getState(runId)!;
    expect(state.completedPhases, hasLength(3));
    expect(state.completedPhases[2].phaseId, equals('work-2'));
    expect(state.completedPhases[2].durationMs, equals(1500000));
    // 55 minutes of active time: 25m work-1 + 5m break-1 + 25m work-2, which
    // is exactly the wall time the run was alive for.
    expect(state.totalActiveElapsedMs, equals(3300000));
    expect(
      state.totalActiveElapsedMs,
      equals(clock.utcNow.difference(startedAt).inMilliseconds),
    );
  });

  test('the ledger stays contiguous across the recovered and live boundary',
      () async {
    await engine.start('multi-routine');
    final runId = engine.activeRunId!;

    engine.dispose();
    clock.advance(const Duration(minutes: 35));

    final recovered = freshEngine();
    await recovered.recover();
    expect(recovered.getState(runId)!.completedPhases, hasLength(2));

    // The app runs on: work-2 has 20 minutes left, then the user ends it.
    clock.advance(const Duration(minutes: 20));
    await pumpEventQueue();
    final result = await recovered.finishPhase(runId);
    expect(result.success, isTrue);

    final entries = recovered.getState(runId)!.completedPhases;
    expect(entries, hasLength(3));

    final lastRecovered = entries[1];
    final live = entries[2];
    // The live entry starts exactly where the last recovered entry ended.
    expect(live.startedAtUtc, equals(lastRecovered.endedAtUtc));
    // And the time it spans is the time it really took.
    expect(
      live.endedAtUtc.difference(live.startedAtUtc).inMilliseconds,
      equals(live.durationMs),
    );
  });
}
