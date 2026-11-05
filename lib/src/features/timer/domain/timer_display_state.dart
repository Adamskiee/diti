import 'package:timer_engine/timer_engine.dart';

class TimerDisplayState {
  final String? runId;
  final String? planBlockId;
  final RunStatus status;
  final PhaseStatus phaseStatus;
  final String phaseName;
  final bool isCountdown;
  final int displayRemainingMs;
  final int displayElapsedMs;
  final double progress;
  final String formattedTime;
  final String cycleDescription;
  final String? nextPhasePreview;
  final int totalSessionElapsedMs;
  final int totalFocusElapsedMs;
  final int totalRestElapsedMs;

  const TimerDisplayState({
    this.runId,
    this.planBlockId,
    this.status = RunStatus.idle,
    this.phaseStatus = PhaseStatus.active,
    this.phaseName = '',
    this.isCountdown = true,
    this.displayRemainingMs = 0,
    this.displayElapsedMs = 0,
    this.progress = 0.0,
    this.formattedTime = '00:00',
    this.cycleDescription = '',
    this.nextPhasePreview,
    this.totalSessionElapsedMs = 0,
    this.totalFocusElapsedMs = 0,
    this.totalRestElapsedMs = 0,
  });

  bool get isActive =>
      status == RunStatus.running ||
      status == RunStatus.paused ||
      phaseStatus == PhaseStatus.awaitingAction;

  bool get isAwaitingAction => phaseStatus == PhaseStatus.awaitingAction;

  TimerDisplayState copyWith({
    String? runId,
    String? planBlockId,
    RunStatus? status,
    PhaseStatus? phaseStatus,
    String? phaseName,
    bool? isCountdown,
    int? displayRemainingMs,
    int? displayElapsedMs,
    double? progress,
    String? formattedTime,
    String? cycleDescription,
    String? Function()? nextPhasePreview,
    int? totalSessionElapsedMs,
    int? totalFocusElapsedMs,
    int? totalRestElapsedMs,
  }) {
    return TimerDisplayState(
      runId: runId ?? this.runId,
      planBlockId: planBlockId ?? this.planBlockId,
      status: status ?? this.status,
      phaseStatus: phaseStatus ?? this.phaseStatus,
      phaseName: phaseName ?? this.phaseName,
      isCountdown: isCountdown ?? this.isCountdown,
      displayRemainingMs: displayRemainingMs ?? this.displayRemainingMs,
      displayElapsedMs: displayElapsedMs ?? this.displayElapsedMs,
      progress: progress ?? this.progress,
      formattedTime: formattedTime ?? this.formattedTime,
      cycleDescription: cycleDescription ?? this.cycleDescription,
      nextPhasePreview:
          nextPhasePreview != null ? nextPhasePreview() : this.nextPhasePreview,
      totalSessionElapsedMs:
          totalSessionElapsedMs ?? this.totalSessionElapsedMs,
      totalFocusElapsedMs: totalFocusElapsedMs ?? this.totalFocusElapsedMs,
      totalRestElapsedMs: totalRestElapsedMs ?? this.totalRestElapsedMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerDisplayState &&
          runtimeType == other.runtimeType &&
          runId == other.runId &&
          planBlockId == other.planBlockId &&
          status == other.status &&
          phaseStatus == other.phaseStatus &&
          phaseName == other.phaseName &&
          isCountdown == other.isCountdown &&
          displayRemainingMs == other.displayRemainingMs &&
          displayElapsedMs == other.displayElapsedMs &&
          progress == other.progress &&
          formattedTime == other.formattedTime &&
          cycleDescription == other.cycleDescription &&
          nextPhasePreview == other.nextPhasePreview &&
          totalSessionElapsedMs == other.totalSessionElapsedMs &&
          totalFocusElapsedMs == other.totalFocusElapsedMs &&
          totalRestElapsedMs == other.totalRestElapsedMs;

  @override
  int get hashCode => Object.hash(
        runId,
        planBlockId,
        status,
        phaseStatus,
        phaseName,
        isCountdown,
        displayRemainingMs,
        displayElapsedMs,
        progress,
        formattedTime,
        cycleDescription,
        nextPhasePreview,
        totalSessionElapsedMs,
        totalFocusElapsedMs,
        totalRestElapsedMs,
      );

  @override
  String toString() =>
      'TimerDisplayState(runId: $runId, planBlockId: $planBlockId, status: $status, '
      'phaseStatus: $phaseStatus, phaseName: $phaseName, formattedTime: $formattedTime, '
      'progress: $progress)';
}
