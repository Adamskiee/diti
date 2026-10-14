import 'dart:math' as math;
import 'package:timer_engine/timer_engine.dart';
import 'scheduled_boundary.dart';

class BoundaryWindowCalculator {
  const BoundaryWindowCalculator();

  static int generateNotificationId(String runId, int phaseIndex, int sequence) {
    final hash = runId.hashCode ^ (phaseIndex * 31 + sequence);
    final positive = hash & 0x7FFFFFFF;
    return positive == 0 ? 1 : positive;
  }

  List<ScheduledBoundary> calculateUpcomingBoundaries({
    required TimerRun run,
    required DateTime currentUtc,
    int maxLookahead = 3,
    Duration maxHorizon = const Duration(hours: 2),
  }) {
    if (run.status != RunStatus.running) return const [];
    if (run.phaseStatus == PhaseStatus.awaitingAction) return const [];

    final snapshot = run.routineSnapshot;
    final phases = snapshot.phases;
    if (phases.isEmpty) return const [];

    final boundaries = <ScheduledBoundary>[];
    int currentPhaseIdx = run.currentPhaseIndex;
    int currentRepeatIdx = run.repeatIndex;
    int accumulatedTimeInPhase = run.accumulatedMs;
    DateTime timelineUtc = currentUtc;
    Duration totalLookaheadDuration = Duration.zero;
    int sequence = 0;

    while (boundaries.length < maxLookahead) {
      if (currentPhaseIdx < 0 || currentPhaseIdx >= phases.length) break;

      final phase = phases[currentPhaseIdx];
      final phaseDurationMs = phase.durationMs;
      if (phaseDurationMs == null) {
        // Open-ended phase has no boundary
        break;
      }

      final remainingMs = math.max(0, phaseDurationMs - accumulatedTimeInPhase);
      final phaseDuration = Duration(milliseconds: remainingMs);

      if (boundaries.isNotEmpty &&
          (totalLookaheadDuration + phaseDuration) > maxHorizon) {
        break;
      }

      timelineUtc = timelineUtc.add(phaseDuration);
      totalLookaheadDuration += phaseDuration;

      // Determine next phase
      final isLastPhaseInCycle = currentPhaseIdx == phases.length - 1;
      bool hasNext = false;
      int nextPhaseIdx = currentPhaseIdx + 1;
      int nextRepeatIdx = currentRepeatIdx;

      if (isLastPhaseInCycle) {
        final repeat = snapshot.repeatRule;
        if (repeat.mode == RepeatMode.forever) {
          hasNext = true;
          nextPhaseIdx = 0;
          nextRepeatIdx = currentRepeatIdx + 1;
        } else if (repeat.mode == RepeatMode.count &&
            (currentRepeatIdx + 1) < repeat.count) {
          hasNext = true;
          nextPhaseIdx = 0;
          nextRepeatIdx = currentRepeatIdx + 1;
        }
      } else {
        hasNext = true;
      }

      final isTerminal = !hasNext;
      final requiresAction = phase.transition == TransitionPolicy.manual;

      String title;
      String body;

      if (isTerminal) {
        title = 'Routine Finished!';
        body = 'Great job! Completed: ${snapshot.name}';
      } else {
        final nextPhase = phases[nextPhaseIdx];
        if (requiresAction) {
          title = 'Phase Complete: ${phase.name}';
          body = 'Tap to start next phase: ${nextPhase.name}';
        } else {
          title = 'Phase Complete: ${phase.name}';
          body = 'Starting next: ${nextPhase.name}';
        }
      }

      boundaries.add(ScheduledBoundary(
        notificationId: generateNotificationId(run.runId, currentPhaseIdx, sequence),
        runId: run.runId,
        phaseIndex: currentPhaseIdx,
        phaseId: phase.id,
        phaseName: phase.name,
        title: title,
        body: body,
        scheduledUtc: timelineUtc,
        requiresAction: requiresAction,
        isTerminal: isTerminal,
      ));

      // If this phase requires manual confirmation or is terminal, stop lookahead
      if (requiresAction || isTerminal) {
        break;
      }

      // Advance to next phase for lookahead
      currentPhaseIdx = nextPhaseIdx;
      currentRepeatIdx = nextRepeatIdx;
      accumulatedTimeInPhase = 0;
      sequence++;
    }

    return boundaries;
  }
}
