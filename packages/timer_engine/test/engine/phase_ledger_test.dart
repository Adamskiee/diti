import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/phase_ledger_entry.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/timer_run.dart';
import 'package:timer_engine/src/domain/timer_run_state.dart';
import 'package:timer_engine/src/engine/timer_engine_impl.dart';
import '../fakes/fake_clock.dart';
import '../fakes/in_memory_notification_port.dart';
import '../fakes/in_memory_persistence_port.dart';
import '../fakes/in_memory_routine_repository.dart';

void main() {
  final start = DateTime.utc(2026, 10, 21, 9, 0);

  PhaseLedgerEntry entry({
    String id = 'focus',
    int durationMs = 60000,
    PhaseKind kind = PhaseKind.focus,
    int phaseIndex = 0,
    int repeatIndex = 0,
  }) =>
      PhaseLedgerEntry(
        phaseId: id,
        phaseName: 'Focus',
        kind: kind,
        phaseIndex: phaseIndex,
        repeatIndex: repeatIndex,
        durationMs: durationMs,
        outcome: PhaseStatus.finished,
        startedAtUtc: start,
        endedAtUtc: start.add(Duration(milliseconds: durationMs)),
      );

  test('PhaseLedgerEntry normalises timestamps to UTC', () {
    final local = DateTime.utc(2026, 10, 21, 9).toLocal();
    final e = PhaseLedgerEntry(
      phaseId: 'p',
      phaseName: 'P',
      kind: PhaseKind.focus,
      phaseIndex: 0,
      repeatIndex: 0,
      durationMs: 1000,
      outcome: PhaseStatus.finished,
      startedAtUtc: local,
      endedAtUtc: local,
    );
    expect(e.startedAtUtc.isUtc, isTrue);
    expect(e.endedAtUtc.isUtc, isTrue);
  });

  test('TimerRun carries a ledger and sums it', () {
    final run = TimerRun(
      runId: 'r1',
      routineSnapshot: _routine(),
      status: RunStatus.running,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: 1,
      repeatIndex: 0,
      accumulatedMs: 0,
      phaseStartedAtUtc: start,
      phaseStartedMonotonicMs: 0,
      stateVersion: 1,
      lastEventId: 'e1',
      phaseLedger: [entry(durationMs: 60000), entry(id: 'brk', durationMs: 30000)],
    );
    expect(run.ledgerTotalMs, 90000);
  });

  test('TimerRunState exposes the ledger and the run total', () {
    final run = TimerRun(
      runId: 'r1',
      routineSnapshot: _routine(),
      status: RunStatus.running,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: 1,
      repeatIndex: 0,
      accumulatedMs: 15000,
      phaseStartedAtUtc: start,
      // The phase's monotonic anchor is the reading the state is calculated
      // at, so no live segment has elapsed yet and the current phase has
      // exactly its 15s of accumulated active time.
      phaseStartedMonotonicMs: 5000,
      stateVersion: 1,
      lastEventId: 'e1',
      phaseLedger: [entry(durationMs: 60000)],
    );
    final state = run.calculateState(currentMonotonicMs: 5000);
    expect(state.completedPhases.length, 1);
    expect(state.totalActiveElapsedMs, 75000);
    expect(state.activeElapsedMs, 15000);
  });

  test('the run total also counts the phase that is still running', () {
    final run = TimerRun(
      runId: 'r1',
      routineSnapshot: _routine(),
      status: RunStatus.running,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: 1,
      repeatIndex: 0,
      accumulatedMs: 15000,
      phaseStartedAtUtc: start,
      phaseStartedMonotonicMs: 0,
      stateVersion: 1,
      phaseLedger: [entry(durationMs: 60000)],
    );
    final state = run.calculateState(currentMonotonicMs: 5000);
    expect(state.activeElapsedMs, 20000);
    expect(state.totalActiveElapsedMs, 80000);
  });

  test('the run keeps its start timestamps and hands them to the state', () {
    final local = start.toLocal();
    final run = TimerRun(
      runId: 'r1',
      routineSnapshot: _routine(),
      status: RunStatus.running,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: 0,
      repeatIndex: 0,
      accumulatedMs: 0,
      phaseStartedAtUtc: start,
      phaseStartedMonotonicMs: 0,
      stateVersion: 1,
      runStartedAtUtc: local,
      phaseFirstStartedAtUtc: local,
    );

    expect(run.runStartedAtUtc?.isUtc, isTrue);
    expect(run.phaseFirstStartedAtUtc?.isUtc, isTrue);
    expect(run.runStartedAtUtc, start);
    expect(run.phaseFirstStartedAtUtc, start);
    expect(run.calculateState(currentMonotonicMs: 0).runStartedAtUtc, start);
  });

  test('copyWith keeps the ledger and the timestamps when they are omitted', () {
    final run = TimerRun(
      runId: 'r1',
      routineSnapshot: _routine(),
      status: RunStatus.running,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: 0,
      repeatIndex: 0,
      accumulatedMs: 0,
      phaseStartedAtUtc: start,
      stateVersion: 1,
      phaseLedger: [entry(durationMs: 60000)],
      runStartedAtUtc: start,
      phaseFirstStartedAtUtc: start,
    );

    final unchanged = run.copyWith(status: RunStatus.paused);
    expect(unchanged.phaseLedger, equals(run.phaseLedger));
    expect(unchanged.runStartedAtUtc, equals(start));
    expect(unchanged.phaseFirstStartedAtUtc, equals(start));

    final later = start.add(const Duration(minutes: 5));
    final changed = run.copyWith(
      phaseLedger: [...run.phaseLedger, entry(id: 'brk', durationMs: 30000)],
      runStartedAtUtc: later,
      phaseFirstStartedAtUtc: later,
    );
    expect(changed.phaseLedger.length, 2);
    expect(changed.ledgerTotalMs, 90000);
    expect(changed.runStartedAtUtc, equals(later));
    expect(changed.phaseFirstStartedAtUtc, equals(later));
  });

  test('TimerRunState equality covers the ledger and the run total', () {
    TimerRunState state({
      List<PhaseLedgerEntry> completedPhases = const [],
      int totalActiveElapsedMs = 0,
    }) =>
        TimerRunState(
          runId: 'r1',
          status: RunStatus.running,
          phaseStatus: PhaseStatus.active,
          currentPhase: _routine().phases[0],
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 1000,
          remainingMs: 5000,
          stateVersion: 1,
          completedPhases: completedPhases,
          totalActiveElapsedMs: totalActiveElapsedMs,
        );

    final one = state(
      completedPhases: [entry(durationMs: 60000)],
      totalActiveElapsedMs: 60000,
    );
    final same = state(
      completedPhases: [entry(durationMs: 60000)],
      totalActiveElapsedMs: 60000,
    );

    expect(one, equals(same));
    expect(one.hashCode, equals(same.hashCode));
    expect(one, isNot(equals(state(completedPhases: const [], totalActiveElapsedMs: 60000))));
    expect(one, isNot(equals(state(completedPhases: [entry(durationMs: 60000)], totalActiveElapsedMs: 70000))));
  });

  group('The engine appends one ledger entry per phase that ends', () {
    late FakeClock clock;
    late InMemoryRoutineRepository routineRepo;
    late InMemoryPersistencePort persistence;
    late InMemoryNotificationPort notifications;
    late TimerEngineImpl engine;

    const pomodoro = Routine(
      id: 'pomodoro',
      name: 'Pomodoro',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [
        RoutinePhase(
          id: 'focus',
          name: 'Focus',
          durationMs: 1500000,
          transition: TransitionPolicy.auto,
          kind: PhaseKind.focus,
        ),
        RoutinePhase(
          id: 'break',
          name: 'Break',
          durationMs: 300000,
          transition: TransitionPolicy.auto,
          kind: PhaseKind.rest,
        ),
      ],
    );

    setUp(() async {
      clock = FakeClock();
      routineRepo = InMemoryRoutineRepository();
      persistence = InMemoryPersistencePort();
      notifications = InMemoryNotificationPort();
      await routineRepo.saveRoutine(pomodoro);

      engine = TimerEngineImpl(
        monotonicClock: clock,
        wallClock: clock,
        routineRepository: routineRepo,
        persistencePort: persistence,
        notificationPort: notifications,
      );
    });

    /// Advances the clock and lets the boundary callback settle.
    ///
    /// The clock is advanced one phase at a time because a boundary
    /// schedules the next one relative to the moment it settles: a single
    /// jump past two boundaries would leave the second phase running.
    Future<void> advancePhase(Duration duration) async {
      clock.advance(duration);
      await pumpEventQueue();
    }

    test('a completed multi-phase run records every phase and reports the sum',
        () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;
      final startedAt = clock.utcNow;
      final focusEndedAt = startedAt.add(const Duration(minutes: 25));
      final runEndedAt = startedAt.add(const Duration(minutes: 30));

      await advancePhase(const Duration(minutes: 25));
      await advancePhase(const Duration(minutes: 5));

      final state = engine.getState(runId)!;
      expect(state.status, equals(RunStatus.completed));
      expect(state.completedPhases, hasLength(2));

      final focus = state.completedPhases[0];
      expect(focus.phaseId, equals('focus'));
      expect(focus.phaseName, equals('Focus'));
      expect(focus.kind, equals(PhaseKind.focus));
      expect(focus.durationMs, equals(1500000));
      expect(focus.outcome, equals(PhaseStatus.finished));
      expect(focus.startedAtUtc, equals(startedAt));
      expect(focus.endedAtUtc, equals(focusEndedAt));

      final rest = state.completedPhases[1];
      expect(rest.phaseId, equals('break'));
      expect(rest.kind, equals(PhaseKind.rest));
      expect(rest.durationMs, equals(300000));
      expect(rest.outcome, equals(PhaseStatus.finished));
      expect(rest.startedAtUtc, equals(focusEndedAt));
      expect(rest.endedAtUtc, equals(runEndedAt));

      final ledgerTotal = state.completedPhases
          .fold<int>(0, (total, entry) => total + entry.durationMs);
      expect(ledgerTotal, equals(1800000));
      expect(state.totalActiveElapsedMs, equals(ledgerTotal));
    });

    test('a phase finished early records its actual elapsed time', () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 10));
      final result = await engine.finishPhase(runId);
      expect(result.success, isTrue);

      final state = engine.getState(runId)!;
      expect(state.completedPhases, hasLength(1));
      final entry = state.completedPhases.single;
      expect(entry.durationMs, equals(600000));
      expect(entry.outcome, equals(PhaseStatus.finished));
      expect(state.totalActiveElapsedMs, equals(600000));
    });

    test('a skipped phase records outcome skipped and its actual elapsed time',
        () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 3));
      final result = await engine.skipPhase(runId);
      expect(result.success, isTrue);

      final state = engine.getState(runId)!;
      expect(state.completedPhases, hasLength(1));
      final entry = state.completedPhases.single;
      expect(entry.outcome, equals(PhaseStatus.skipped));
      expect(entry.durationMs, equals(180000));
    });

    test('a cancelled run records the in-progress phase as its own final entry',
        () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 7));
      final result = await engine.stop(runId);
      expect(result.success, isTrue);

      final state = engine.getState(runId)!;
      expect(state.status, equals(RunStatus.cancelled));
      expect(state.completedPhases, hasLength(1));
      final entry = state.completedPhases.single;
      expect(entry.durationMs, equals(420000));
      expect(entry.outcome, equals(PhaseStatus.finished));
      expect(state.totalActiveElapsedMs, equals(420000));
    });

    test('a phase that runs past its configured length records the overrun',
        () async {
      await routineRepo.saveRoutine(Routine(
        id: 'manual',
        name: 'Manual',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'reading',
            name: 'Reading',
            durationMs: 1500000,
            transition: TransitionPolicy.manual,
            kind: PhaseKind.focus,
          ),
        ],
      ));
      await engine.start('manual');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 27));
      await pumpEventQueue();
      final awaiting = engine.getState(runId)!;
      expect(awaiting.phaseStatus, equals(PhaseStatus.awaitingAction));

      final result = await engine.finishPhase(runId);
      expect(result.success, isTrue);

      final state = engine.getState(runId)!;
      expect(state.completedPhases, hasLength(1));
      // 27 minutes of actual time, not the configured 25.
      expect(state.completedPhases.single.durationMs, equals(1620000));
      expect(state.totalActiveElapsedMs, equals(1620000));
    });

    test('a completed run keeps the last phase first start, not the run end',
        () async {
      await engine.start('pomodoro');

      await advancePhase(const Duration(minutes: 25));
      final breakStartedAt = clock.utcNow;
      await advancePhase(const Duration(minutes: 5));

      final persisted = persistence.activeRun!;
      expect(persisted.phaseFirstStartedAtUtc, equals(breakStartedAt));
      expect(persisted.phaseFirstStartedAtUtc, isNot(equals(clock.utcNow)));
    });

    test('the accumulator is zero after the run completes', () async {
      await engine.start('pomodoro');

      await advancePhase(const Duration(minutes: 25));
      await advancePhase(const Duration(minutes: 5));

      final persisted = persistence.activeRun!;
      expect(persisted.accumulatedMs, equals(0));
      expect(persisted.ledgerTotalMs, equals(1800000));
    });

    test('the run total holds mid-phase, not only at a boundary', () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      await advancePhase(const Duration(minutes: 25));
      clock.advance(const Duration(minutes: 3));
      await pumpEventQueue();

      final state = engine.getState(runId)!;
      expect(state.activeElapsedMs, equals(180000));
      expect(state.totalActiveElapsedMs, equals(1500000 + 180000));
    });

    test('the accumulator is zero when a phase ends', () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 10));
      await engine.finishPhase(runId);

      final persisted = persistence.activeRun!;
      expect(persisted.accumulatedMs, equals(0));
      expect(persisted.ledgerTotalMs, equals(600000));
      expect(persisted.phaseLedger, hasLength(1));
    });

    test('elapsed() reports the run total, not the last phase', () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      await advancePhase(const Duration(minutes: 25));
      await advancePhase(const Duration(minutes: 5));

      expect(await engine.elapsed(runId), equals(const Duration(minutes: 30)));
    });

    test('the run records its true start and the phase its first start',
        () async {
      await engine.start('pomodoro');

      final persisted = persistence.activeRun!;
      expect(persisted.runStartedAtUtc, equals(clock.utcNow));
      expect(persisted.phaseFirstStartedAtUtc, equals(clock.utcNow));
    });

    test('a pause and a resume keep the phase first start', () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;
      final startedAt = clock.utcNow;

      clock.advance(const Duration(minutes: 3));
      await engine.pause(runId);
      clock.advance(const Duration(minutes: 20));
      await engine.resume(runId);

      final persisted = persistence.activeRun!;
      expect(persisted.runStartedAtUtc, equals(startedAt));
      expect(persisted.phaseFirstStartedAtUtc, equals(startedAt));
    });

    test('paused time is excluded from the phase and from the run total',
        () async {
      await engine.start('pomodoro');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 10));
      await engine.pause(runId);
      clock.advance(const Duration(minutes: 30));
      await engine.resume(runId);
      clock.advance(const Duration(minutes: 5));
      await engine.finishPhase(runId);

      final state = engine.getState(runId)!;
      expect(state.completedPhases, hasLength(1));
      expect(state.completedPhases.single.durationMs, equals(900000));
      expect(state.totalActiveElapsedMs, equals(900000));
    });

    test('a forever-repeating routine produces one entry per phase occurrence',
        () async {
      await routineRepo.saveRoutine(Routine(
        id: 'forever',
        name: 'Forever',
        repeatRule: const RepeatRule(mode: RepeatMode.forever),
        phases: pomodoro.phases,
      ));
      await engine.start('forever');
      final runId = engine.activeRunId!;

      await advancePhase(const Duration(minutes: 25));
      await advancePhase(const Duration(minutes: 5));
      await advancePhase(const Duration(minutes: 25));
      await advancePhase(const Duration(minutes: 5));

      final state = engine.getState(runId)!;
      expect(state.completedPhases, hasLength(4));
      expect(
        state.completedPhases.map((entry) => entry.phaseId).toList(),
        equals(['focus', 'break', 'focus', 'break']),
      );
      expect(
        state.completedPhases.map((entry) => entry.repeatIndex).toList(),
        equals([0, 0, 1, 1]),
      );
      expect(
        state.completedPhases.map((entry) => entry.durationMs).toList(),
        equals([1500000, 300000, 1500000, 300000]),
      );
    });
  });
}

Routine _routine() => Routine(
      id: 'routine-1',
      name: 'Pomodoro',
      repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
      phases: const [
        RoutinePhase(
          id: 'focus',
          name: 'Focus',
          durationMs: 1500000,
          transition: TransitionPolicy.auto,
          kind: PhaseKind.focus,
        ),
        RoutinePhase(
          id: 'break',
          name: 'Break',
          durationMs: 300000,
          transition: TransitionPolicy.auto,
          kind: PhaseKind.rest,
        ),
      ],
    );
