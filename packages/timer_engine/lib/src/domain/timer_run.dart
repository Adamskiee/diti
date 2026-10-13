import 'dart:math' as math;
import 'enums.dart';
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
  })  : phaseStartedAtUtc =
            phaseStartedAtUtc.isUtc ? phaseStartedAtUtc : phaseStartedAtUtc.toUtc(),
        pausedAtUtc = pausedAtUtc == null
            ? null
            : (pausedAtUtc.isUtc ? pausedAtUtc : pausedAtUtc.toUtc());

  RoutinePhase get currentPhase => routineSnapshot.phases[currentPhaseIndex];

  TimerRunState calculateState({required int currentMonotonicMs}) {
    int activeMs = accumulatedMs;
    if (status == RunStatus.running && phaseStartedMonotonicMs != null) {
      final delta = math.max(0, currentMonotonicMs - phaseStartedMonotonicMs!);
      activeMs += delta;
    }

    int? remaining;
    final duration = currentPhase.durationMs;
    if (duration != null) {
      remaining = math.max(0, duration - activeMs);
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
    );
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
          lastEventId == other.lastEventId;

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
      );
}
