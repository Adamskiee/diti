import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/phase_ledger_entry.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/timer_run.dart';
import 'package:timer_engine/src/domain/timer_run_state.dart';

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
