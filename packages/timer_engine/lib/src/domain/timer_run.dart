import 'dart:math' as math;
import 'enums.dart';
import 'phase_ledger_entry.dart';
import 'routine.dart';
import 'routine_phase.dart';
import 'timer_run_state.dart';

class TimerRun {
  final String runId;
  final Routine routineSnapshot;
  final RunStatus status;
  final PhaseStatus phaseStatus;
  final int currentPhaseIndex;
  final int repeatIndex;
  final int accumulatedMs;
  final DateTime phaseStartedAtUtc;
  final int? phaseStartedMonotonicMs;
  final DateTime? pausedAtUtc;
  final int stateVersion;
  final String? lastEventId;

  /// The phases that have ended, in the order they ended, with the active
  /// time each of them actually took.
  final List<PhaseLedgerEntry> phaseLedger;

  /// When the run really started, ignoring pauses and phase changes.
  final DateTime? runStartedAtUtc;

  /// When the phase that is currently running first started running. It
  /// survives pauses and resumes, so a phase that is paused and resumed is
  /// still measured from its first start.
  ///
  /// It is the *next* phase's first start once a phase advances, so a run
  /// that continues points at the phase it is on. A run that has ended
  /// keeps the first start of the phase that was running when it ended:
  /// the run's end is never stamped onto it.
  final DateTime? phaseFirstStartedAtUtc;

  TimerRun({
    required this.runId,
    required this.routineSnapshot,
    required this.status,
    required this.phaseStatus,
    required this.currentPhaseIndex,
    required this.repeatIndex,
    required this.accumulatedMs,
    required DateTime phaseStartedAtUtc,
    this.phaseStartedMonotonicMs,
    DateTime? pausedAtUtc,
    required this.stateVersion,
    this.lastEventId,
    this.phaseLedger = const [],
    DateTime? runStartedAtUtc,
    DateTime? phaseFirstStartedAtUtc,
  })  : phaseStartedAtUtc = phaseStartedAtUtc.isUtc
            ? phaseStartedAtUtc
            : phaseStartedAtUtc.toUtc(),
        pausedAtUtc = pausedAtUtc == null
            ? null
            : (pausedAtUtc.isUtc ? pausedAtUtc : pausedAtUtc.toUtc()),
        runStartedAtUtc = runStartedAtUtc == null
            ? null
            : (runStartedAtUtc.isUtc
                ? runStartedAtUtc
                : runStartedAtUtc.toUtc()),
        phaseFirstStartedAtUtc = phaseFirstStartedAtUtc == null
            ? null
            : (phaseFirstStartedAtUtc.isUtc
                ? phaseFirstStartedAtUtc
                : phaseFirstStartedAtUtc.toUtc());

  RoutinePhase get currentPhase => routineSnapshot.phases[currentPhaseIndex];

  /// The active time of every phase that has ended.
  int get ledgerTotalMs =>
      phaseLedger.fold(0, (sum, entry) => sum + entry.durationMs);

  TimerRunState calculateState({required int currentMonotonicMs}) {
    int activeMs = accumulatedMs;
    if (status == RunStatus.running && phaseStartedMonotonicMs != null) {
      final delta = math.max(0, currentMonotonicMs - phaseStartedMonotonicMs!);
      activeMs += delta;
    }

    int? remaining;
    final duration = currentPhase.durationMs;
    if (duration != null) {
      if (currentPhase.kind == PhaseKind.rest) {
        remaining = duration - activeMs;
      } else {
        remaining = math.max(0, duration - activeMs);
      }
    }

    return TimerRunState(
      runId: runId,
      status: status,
      phaseStatus: phaseStatus,
      currentPhase: currentPhase,
      currentPhaseIndex: currentPhaseIndex,
      repeatIndex: repeatIndex,
      activeElapsedMs: activeMs,
      remainingMs: remaining,
      stateVersion: stateVersion,
      completedPhases: phaseLedger,
      totalActiveElapsedMs: ledgerTotalMs + activeMs,
      runStartedAtUtc: runStartedAtUtc,
    );
  }

  TimerRun copyWith({
    String? runId,
    Routine? routineSnapshot,
    RunStatus? status,
    PhaseStatus? phaseStatus,
    int? currentPhaseIndex,
    int? repeatIndex,
    int? accumulatedMs,
    DateTime? phaseStartedAtUtc,
    int? Function()? phaseStartedMonotonicMs,
    DateTime? Function()? pausedAtUtc,
    int? stateVersion,
    String? Function()? lastEventId,
    List<PhaseLedgerEntry>? phaseLedger,
    DateTime? runStartedAtUtc,
    DateTime? phaseFirstStartedAtUtc,
  }) {
    return TimerRun(
      runId: runId ?? this.runId,
      routineSnapshot: routineSnapshot ?? this.routineSnapshot,
      status: status ?? this.status,
      phaseStatus: phaseStatus ?? this.phaseStatus,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      repeatIndex: repeatIndex ?? this.repeatIndex,
      accumulatedMs: accumulatedMs ?? this.accumulatedMs,
      phaseStartedAtUtc: phaseStartedAtUtc ?? this.phaseStartedAtUtc,
      phaseStartedMonotonicMs: phaseStartedMonotonicMs != null
          ? phaseStartedMonotonicMs()
          : this.phaseStartedMonotonicMs,
      pausedAtUtc: pausedAtUtc != null ? pausedAtUtc() : this.pausedAtUtc,
      stateVersion: stateVersion ?? this.stateVersion,
      lastEventId: lastEventId != null ? lastEventId() : this.lastEventId,
      phaseLedger: phaseLedger ?? this.phaseLedger,
      runStartedAtUtc: runStartedAtUtc ?? this.runStartedAtUtc,
      phaseFirstStartedAtUtc:
          phaseFirstStartedAtUtc ?? this.phaseFirstStartedAtUtc,
    );
  }

  bool _sameLedger(List<PhaseLedgerEntry> other) {
    if (phaseLedger.length != other.length) return false;
    for (var i = 0; i < phaseLedger.length; i++) {
      if (phaseLedger[i] != other[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerRun &&
          runtimeType == other.runtimeType &&
          runId == other.runId &&
          routineSnapshot == other.routineSnapshot &&
          status == other.status &&
          phaseStatus == other.phaseStatus &&
          currentPhaseIndex == other.currentPhaseIndex &&
          repeatIndex == other.repeatIndex &&
          accumulatedMs == other.accumulatedMs &&
          phaseStartedAtUtc == other.phaseStartedAtUtc &&
          phaseStartedMonotonicMs == other.phaseStartedMonotonicMs &&
          pausedAtUtc == other.pausedAtUtc &&
          stateVersion == other.stateVersion &&
          lastEventId == other.lastEventId &&
          _sameLedger(other.phaseLedger) &&
          runStartedAtUtc == other.runStartedAtUtc &&
          phaseFirstStartedAtUtc == other.phaseFirstStartedAtUtc;

  @override
  int get hashCode => Object.hash(
        runId,
        routineSnapshot,
        status,
        phaseStatus,
        currentPhaseIndex,
        repeatIndex,
        accumulatedMs,
        phaseStartedAtUtc,
        phaseStartedMonotonicMs,
        pausedAtUtc,
        stateVersion,
        lastEventId,
        Object.hashAll(phaseLedger),
        runStartedAtUtc,
        phaseFirstStartedAtUtc,
      );
}
