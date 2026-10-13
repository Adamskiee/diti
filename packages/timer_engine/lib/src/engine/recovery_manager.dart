import 'dart:math' as math;
import '../clock/wall_clock.dart';
import '../domain/enums.dart';
import '../domain/timer_event.dart';
import '../domain/timer_run.dart';

class ReconciledState {
  final TimerRun run;
  final List<TimerEvent> events;

  const ReconciledState({required this.run, required this.events});
}

class RecoveryManager {
  final WallClock wallClock;

  const RecoveryManager({required this.wallClock});

  ReconciledState reconcile(TimerRun activeRun, int nowMonoMs) {
    if (activeRun.status != RunStatus.running) {
      return ReconciledState(run: activeRun, events: const []);
    }

    final nowUtc = wallClock.utcNow;
    final totalWallElapsedMs =
        math.max(0, nowUtc.difference(activeRun.phaseStartedAtUtc).inMilliseconds);
    int remainingDeltaMs = activeRun.accumulatedMs + totalWallElapsedMs;

    var currentRun = activeRun;
    final events = <TimerEvent>[];
    final routine = activeRun.routineSnapshot;
    final numPhases = routine.phases.length;

    while (true) {
      final currentPhase = routine.phases[currentRun.currentPhaseIndex];
      final duration = currentPhase.durationMs;

      if (duration == null) {
        // Open-ended phase: consumes all remaining delta without advancing
        final hasTransitioned = currentRun != activeRun;
        currentRun = currentRun.copyWith(
          accumulatedMs: remainingDeltaMs,
          phaseStartedAtUtc: nowUtc,
          phaseStartedMonotonicMs: () => nowMonoMs,
          stateVersion: currentRun.stateVersion + (hasTransitioned ? 1 : 0),
        );
        break;
      }

      if (remainingDeltaMs < duration) {
        // Within the current phase
        final hasTransitioned = currentRun != activeRun;
        currentRun = currentRun.copyWith(
          accumulatedMs: remainingDeltaMs,
          phaseStartedAtUtc: nowUtc,
          phaseStartedMonotonicMs: () => nowMonoMs,
          stateVersion: currentRun.stateVersion + (hasTransitioned ? 1 : 0),
        );
        break;
      }

      // Phase duration elapsed
      if (currentPhase.transition == TransitionPolicy.manual) {
        // Manual barrier! Do not advance past manual phase
        final hasTransitioned =
            activeRun.phaseStatus != PhaseStatus.awaitingAction || currentRun != activeRun;
        currentRun = currentRun.copyWith(
          phaseStatus: PhaseStatus.awaitingAction,
          accumulatedMs: remainingDeltaMs,
          phaseStartedAtUtc: nowUtc,
          phaseStartedMonotonicMs: () => nowMonoMs,
          stateVersion: currentRun.stateVersion + (hasTransitioned ? 1 : 0),
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
        if (repeatRule.mode == RepeatMode.forever || newRepeatIndex < repeatRule.count - 1) {
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
          eventId: 'reconciled-${events.length}-${nowUtc.millisecondsSinceEpoch}',
          runId: currentRun.runId,
          type: TimerEventType.phaseFinished,
          occurredAtUtc: nowUtc,
          durationMs: duration,
          metadata: const {'reconciled': true},
        );
        final runCompletedEvent = TimerEvent(
          eventId: 'reconciled-${events.length + 1}-${nowUtc.millisecondsSinceEpoch}',
          runId: currentRun.runId,
          type: TimerEventType.runCompleted,
          occurredAtUtc: nowUtc,
          metadata: const {'reconciled': true},
        );
        events.addAll([phaseEvent, runCompletedEvent]);
      } else {
        events.add(TimerEvent(
          eventId: 'reconciled-${events.length}-${nowUtc.millisecondsSinceEpoch}',
          runId: currentRun.runId,
          type: TimerEventType.phaseFinished,
          occurredAtUtc: nowUtc,
          durationMs: duration,
          metadata: const {'reconciled': true},
        ));
      }

      currentRun = currentRun.copyWith(
        status: newStatus,
        phaseStatus: isCompleted ? PhaseStatus.finished : PhaseStatus.active,
        currentPhaseIndex: newPhaseIndex,
        repeatIndex: newRepeatIndex,
        accumulatedMs: isCompleted ? duration : 0,
        phaseStartedAtUtc: nowUtc,
        phaseStartedMonotonicMs: () => newStatus == RunStatus.running ? nowMonoMs : null,
        stateVersion: currentRun.stateVersion + 1,
        lastEventId: () => events.last.eventId,
      );

      if (isCompleted) {
        break;
      }
    }

    return ReconciledState(run: currentRun, events: events);
  }
}
