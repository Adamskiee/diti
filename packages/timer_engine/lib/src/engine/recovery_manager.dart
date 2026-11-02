import 'dart:math' as math;
import '../clock/wall_clock.dart';
import '../domain/enums.dart';
import '../domain/phase_ledger_entry.dart';
import '../domain/timer_event.dart';
import '../domain/timer_run.dart';

class ReconciledState {
  final TimerRun run;
  final List<TimerEvent> events;

  const ReconciledState({required this.run, required this.events});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconciledState &&
          runtimeType == other.runtimeType &&
          run == other.run &&
          _listEquals(events, other.events);

  @override
  int get hashCode => Object.hash(run, Object.hashAll(events));

  static bool _listEquals(List<TimerEvent> a, List<TimerEvent> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class RecoveryManager {
  final WallClock wallClock;

  const RecoveryManager({required this.wallClock});

  ReconciledState reconcile(TimerRun activeRun, int nowMonoMs) {
    if (activeRun.status != RunStatus.running) {
      return ReconciledState(run: activeRun, events: const []);
    }

    final nowUtc = wallClock.utcNow;
    final totalWallElapsedMs = math.max(
        0, nowUtc.difference(activeRun.phaseStartedAtUtc).inMilliseconds);
    int remainingDeltaMs = activeRun.accumulatedMs + totalWallElapsedMs;

    var currentRun = activeRun;
    final events = <TimerEvent>[];
    final ledgerEntries = <PhaseLedgerEntry>[];
    final routine = activeRun.routineSnapshot;
    final numPhases = routine.phases.length;

    // The reconstructed wall clock: the end of the last phase that ended is
    // the start of the phase that comes next. The phases crossed while the
    // app was dead are laid out forward from the phase the run was on.
    //
    // The reconstruction is a wall-clock approximation: it knows the phase
    // lengths, not when the run was actually running, so a pause in the run's
    // history shifts the reconstructed spans. The recorded *durations* are
    // exact — paused time is never counted — but the spans are a
    // reconstruction, not a record of when the phase really ran.
    var phaseEndUtc =
        activeRun.phaseFirstStartedAtUtc ?? activeRun.phaseStartedAtUtc;

    while (true) {
      final currentPhase = routine.phases[currentRun.currentPhaseIndex];
      final duration = currentPhase.durationMs;

      if (duration == null) {
        // Open-ended phase: consumes all remaining delta without advancing
        final shouldIncrement = currentRun == activeRun
            ? remainingDeltaMs != activeRun.accumulatedMs
            : false;
        currentRun = currentRun.copyWith(
          accumulatedMs: remainingDeltaMs,
          phaseStartedAtUtc: nowUtc,
          phaseStartedMonotonicMs: () => nowMonoMs,
          stateVersion: currentRun.stateVersion + (shouldIncrement ? 1 : 0),
        );
        break;
      }

      if (remainingDeltaMs < duration) {
        // Within the current phase
        final shouldIncrement = currentRun == activeRun
            ? remainingDeltaMs != activeRun.accumulatedMs
            : false;
        currentRun = currentRun.copyWith(
          accumulatedMs: remainingDeltaMs,
          phaseStartedAtUtc: nowUtc,
          phaseStartedMonotonicMs: () => nowMonoMs,
          stateVersion: currentRun.stateVersion + (shouldIncrement ? 1 : 0),
        );
        break;
      }

      // Phase duration elapsed
      if (currentPhase.transition == TransitionPolicy.manual) {
        // Manual barrier! Do not advance past manual phase
        final shouldIncrement = currentRun == activeRun
            ? (activeRun.phaseStatus != PhaseStatus.awaitingAction ||
                remainingDeltaMs != activeRun.accumulatedMs)
            : (currentRun.phaseStatus != PhaseStatus.awaitingAction);
        currentRun = currentRun.copyWith(
          phaseStatus: PhaseStatus.awaitingAction,
          accumulatedMs: remainingDeltaMs,
          phaseStartedAtUtc: nowUtc,
          phaseStartedMonotonicMs: () => nowMonoMs,
          stateVersion: currentRun.stateVersion + (shouldIncrement ? 1 : 0),
        );
        break;
      }

      // Auto phase advances
      remainingDeltaMs -= duration;
      final nextPhaseIndex = currentRun.currentPhaseIndex + 1;
      int newPhaseIndex = nextPhaseIndex;
      int newRepeatIndex = currentRun.repeatIndex;
      RunStatus newStatus = RunStatus.running;

      if (nextPhaseIndex >= numPhases) {
        final repeatRule = routine.repeatRule;
        if (repeatRule.mode == RepeatMode.forever ||
            newRepeatIndex < repeatRule.count - 1) {
          newPhaseIndex = 0;
          newRepeatIndex += 1;
        } else {
          newPhaseIndex = currentRun.currentPhaseIndex;
          newStatus = RunStatus.completed;
        }
      }

      final isCompleted = newStatus == RunStatus.completed;
      if (isCompleted) {
        final phaseEvent = TimerEvent(
          eventId:
              'reconciled-${events.length}-${nowUtc.millisecondsSinceEpoch}',
          runId: currentRun.runId,
          type: TimerEventType.phaseFinished,
          occurredAtUtc: nowUtc,
          durationMs: duration,
          metadata: const {'reconciled': true},
        );
        final runCompletedEvent = TimerEvent(
          eventId:
              'reconciled-${events.length + 1}-${nowUtc.millisecondsSinceEpoch}',
          runId: currentRun.runId,
          type: TimerEventType.runCompleted,
          occurredAtUtc: nowUtc,
          metadata: const {'reconciled': true},
        );
        events.addAll([phaseEvent, runCompletedEvent]);
      } else {
        events.add(TimerEvent(
          eventId:
              'reconciled-${events.length}-${nowUtc.millisecondsSinceEpoch}',
          runId: currentRun.runId,
          type: TimerEventType.phaseFinished,
          occurredAtUtc: nowUtc,
          durationMs: duration,
          metadata: const {'reconciled': true},
        ));
      }

      // The phase is over: it ran its whole length while the app was dead,
      // so its active time moves into the ledger and the accumulator starts
      // the next phase from zero.
      final phaseStartUtc = phaseEndUtc;
      final phaseEndCandidate =
          phaseStartUtc.add(Duration(milliseconds: duration));
      // The reconstruction can never place a phase's end after the moment
      // recovery ran.
      phaseEndUtc =
          phaseEndCandidate.isAfter(nowUtc) ? nowUtc : phaseEndCandidate;

      ledgerEntries.add(PhaseLedgerEntry(
        phaseId: currentPhase.id,
        phaseName: currentPhase.name,
        kind: currentPhase.kind,
        phaseIndex: currentRun.currentPhaseIndex,
        repeatIndex: currentRun.repeatIndex,
        durationMs: duration,
        outcome: PhaseStatus.finished,
        startedAtUtc: phaseStartUtc,
        endedAtUtc: phaseEndUtc,
      ));

      currentRun = currentRun.copyWith(
        status: newStatus,
        phaseStatus: isCompleted ? PhaseStatus.finished : PhaseStatus.active,
        currentPhaseIndex: newPhaseIndex,
        repeatIndex: newRepeatIndex,
        accumulatedMs: 0,
        // The phase that is current now started when the phase just crossed
        // ended, in the reconstructed wall clock. `phaseStartedAtUtc` is the
        // current *segment's* start and is reset on every resume, while this
        // is the phase's *first* start and survives one — the same difference
        // the live engine's resume path keeps. An ended run keeps the first
        // start of the phase that just ended.
        phaseFirstStartedAtUtc: isCompleted ? phaseStartUtc : phaseEndUtc,
        phaseStartedAtUtc: nowUtc,
        phaseStartedMonotonicMs: () =>
            newStatus == RunStatus.running ? nowMonoMs : null,
        stateVersion: currentRun.stateVersion + 1,
        lastEventId: () => events.last.eventId,
      );

      if (isCompleted) {
        break;
      }
    }

    // The ledger is built once, here: the phases the run had already recorded
    // plus the ones this reconciliation crossed.
    if (ledgerEntries.isNotEmpty) {
      currentRun = currentRun.copyWith(
        phaseLedger: [...activeRun.phaseLedger, ...ledgerEntries],
      );
    }

    return ReconciledState(run: currentRun, events: events);
  }
}
