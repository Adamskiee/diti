import 'enums.dart';
import 'phase_ledger_entry.dart';
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

  /// The phases that have ended, with the active time each of them took.
  final List<PhaseLedgerEntry> completedPhases;

  /// The active time of the whole run: the phases that ended plus the phase
  /// that is running now.
  final int totalActiveElapsedMs;

  /// When the run really started, ignoring pauses and phase changes.
  final DateTime? runStartedAtUtc;

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
    this.completedPhases = const [],
    this.totalActiveElapsedMs = 0,
    this.runStartedAtUtc,
  });

  int get currentRepetition => repeatIndex + 1;
  String get phaseName => currentPhase.name;

  /// The active time spent in focus phases across the entire run so far.
  int get totalFocusElapsedMs {
    var total = completedPhases
        .where((p) => p.kind == PhaseKind.focus)
        .fold<int>(0, (sum, p) => sum + p.durationMs);
    if (status != RunStatus.completed &&
        status != RunStatus.cancelled &&
        currentPhase.kind == PhaseKind.focus) {
      total += activeElapsedMs;
    }
    return total;
  }

  /// The active time spent in rest phases across the entire run so far.
  int get totalRestElapsedMs {
    var total = completedPhases
        .where((p) => p.kind == PhaseKind.rest)
        .fold<int>(0, (sum, p) => sum + p.durationMs);
    if (status != RunStatus.completed &&
        status != RunStatus.cancelled &&
        currentPhase.kind == PhaseKind.rest) {
      total += activeElapsedMs;
    }
    return total;
  }

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
    List<PhaseLedgerEntry>? completedPhases,
    int? totalActiveElapsedMs,
    DateTime? runStartedAtUtc,
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
      completedPhases: completedPhases ?? this.completedPhases,
      totalActiveElapsedMs: totalActiveElapsedMs ?? this.totalActiveElapsedMs,
      runStartedAtUtc: runStartedAtUtc ?? this.runStartedAtUtc,
    );
  }

  bool _sameCompletedPhases(List<PhaseLedgerEntry> other) {
    if (completedPhases.length != other.length) return false;
    for (var i = 0; i < completedPhases.length; i++) {
      if (completedPhases[i] != other[i]) return false;
    }
    return true;
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
          stateVersion == other.stateVersion &&
          _sameCompletedPhases(other.completedPhases) &&
          totalActiveElapsedMs == other.totalActiveElapsedMs &&
          runStartedAtUtc == other.runStartedAtUtc;

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
        Object.hashAll(completedPhases),
        totalActiveElapsedMs,
        runStartedAtUtc,
      );
}
