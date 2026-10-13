import 'enums.dart';
import 'routine_phase.dart';

class TimerRunState {
  final String runId;
  final RunStatus status;
  final PhaseStatus phaseStatus;
  final RoutinePhase currentPhase;
  final int currentPhaseIndex;
  final int repeatIndex;
  final int activeElapsedMs;
  final int? remainingMs;
  final int stateVersion;

  const TimerRunState({
    required this.runId,
    required this.status,
    required this.phaseStatus,
    required this.currentPhase,
    required this.currentPhaseIndex,
    required this.repeatIndex,
    required this.activeElapsedMs,
    this.remainingMs,
    required this.stateVersion,
  });

  int get currentRepetition => repeatIndex + 1;

  TimerRunState copyWith({
    String? runId,
    RunStatus? status,
    PhaseStatus? phaseStatus,
    RoutinePhase? currentPhase,
    int? currentPhaseIndex,
    int? repeatIndex,
    int? activeElapsedMs,
    int? Function()? remainingMs,
    int? stateVersion,
  }) {
    return TimerRunState(
      runId: runId ?? this.runId,
      status: status ?? this.status,
      phaseStatus: phaseStatus ?? this.phaseStatus,
      currentPhase: currentPhase ?? this.currentPhase,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      repeatIndex: repeatIndex ?? this.repeatIndex,
      activeElapsedMs: activeElapsedMs ?? this.activeElapsedMs,
      remainingMs: remainingMs != null ? remainingMs() : this.remainingMs,
      stateVersion: stateVersion ?? this.stateVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerRunState &&
          runtimeType == other.runtimeType &&
          runId == other.runId &&
          status == other.status &&
          phaseStatus == other.phaseStatus &&
          currentPhase == other.currentPhase &&
          currentPhaseIndex == other.currentPhaseIndex &&
          repeatIndex == other.repeatIndex &&
          activeElapsedMs == other.activeElapsedMs &&
          remainingMs == other.remainingMs &&
          stateVersion == other.stateVersion;

  @override
  int get hashCode => Object.hash(
        runId,
        status,
        phaseStatus,
        currentPhase,
        currentPhaseIndex,
        repeatIndex,
        activeElapsedMs,
        remainingMs,
        stateVersion,
      );
}
