import 'package:timer_engine/timer_engine.dart';

class TimerDisplayState {
  final String? runId;
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

  const TimerDisplayState({
    this.runId,
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
  });

  bool get isActive =>
      status == RunStatus.running ||
      status == RunStatus.paused ||
      phaseStatus == PhaseStatus.awaitingAction;

  bool get isAwaitingAction => phaseStatus == PhaseStatus.awaitingAction;

  TimerDisplayState copyWith({
    String? runId,
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
  }) {
    return TimerDisplayState(
      runId: runId ?? this.runId,
      status: status ?? this.status,
      phaseStatus: phaseStatus ?? this.phaseStatus,
      phaseName: phaseName ?? this.phaseName,
      isCountdown: isCountdown ?? this.isCountdown,
      displayRemainingMs: displayRemainingMs ?? this.displayRemainingMs,
      displayElapsedMs: displayElapsedMs ?? this.displayElapsedMs,
      progress: progress ?? this.progress,
      formattedTime: formattedTime ?? this.formattedTime,
      cycleDescription: cycleDescription ?? this.cycleDescription,
      nextPhasePreview: nextPhasePreview != null
          ? nextPhasePreview()
          : this.nextPhasePreview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerDisplayState &&
          runtimeType == other.runtimeType &&
          runId == other.runId &&
          status == other.status &&
          phaseStatus == other.phaseStatus &&
          phaseName == other.phaseName &&
          isCountdown == other.isCountdown &&
          displayRemainingMs == other.displayRemainingMs &&
          displayElapsedMs == other.displayElapsedMs &&
          progress == other.progress &&
          formattedTime == other.formattedTime &&
          cycleDescription == other.cycleDescription &&
          nextPhasePreview == other.nextPhasePreview;

  @override
  int get hashCode => Object.hash(
        runId,
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
      );

  @override
  String toString() =>
      'TimerDisplayState(runId: $runId, status: $status, phaseStatus: $phaseStatus, '
      'phaseName: $phaseName, formattedTime: $formattedTime, progress: $progress)';
}
