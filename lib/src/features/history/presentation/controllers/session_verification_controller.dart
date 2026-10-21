import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';
import '../../domain/draft_session.dart';

class SessionVerificationController extends StateNotifier<DraftSessionState> {
  final SessionRepository _sessionRepository;
  final PlanBlockRepository _planBlockRepository;
  final void Function()? _onSessionSaved;

  SessionVerificationController({
    required SessionRepository sessionRepository,
    required PlanBlockRepository planBlockRepository,
    void Function()? onSessionSaved,
  })  : _sessionRepository = sessionRepository,
        _planBlockRepository = planBlockRepository,
        _onSessionSaved = onSessionSaved,
        super(const DraftSessionState());

  static const int minNoiseDurationMs = 60000; // 60 seconds

  Future<void> prepareVerification({
    required TimerRunState runState,
    required Routine routineSnapshot,
    String? planBlockId,
    DateTime? nowUtc,
  }) async {
    // The run's total active time: every phase that ended plus the phase
    // that was running. Never the current phase alone — that would drop the
    // focus time of a run that was cancelled during its break.
    final totalDurationMs = runState.totalActiveElapsedMs;

    // Noise filter: prune cancelled micro-sessions < 60s, and every run
    // without measurable time — such a session cannot be saved at all.
    final isNoise = runState.status == RunStatus.cancelled &&
        totalDurationMs < minNoiseDurationMs;
    final hasNoMeasurableTime =
        totalDurationMs < SessionValidator.minDurationMs;
    if (isNoise || hasNoMeasurableTime) {
      if (planBlockId != null) {
        await _revertPlanBlock(planBlockId);
      }
      state = const DraftSessionState();
      return;
    }

    final end = nowUtc ?? DateTime.now().toUtc();
    // The session starts when the run started. A pause inside the run makes
    // the wall-clock span longer than the active time, so a start derived
    // from the active time would push the earlier phases' events out of the
    // session's window and the session could not be saved.
    final start = runState.runStartedAtUtc ??
        end.subtract(Duration(milliseconds: totalDurationMs));
    final outcome = runState.status == RunStatus.completed
        ? SessionOutcome.completed
        : SessionOutcome.cancelled;

    final sessionId = const Uuid().v4();
    final breakdown = List<PhaseLedgerEntry>.of(runState.completedPhases);

    final candidate = SessionRecord(
      sessionId: sessionId,
      routineId: routineSnapshot.id,
      planBlockId: planBlockId,
      routineName: routineSnapshot.name,
      startedAtUtc: start,
      endedAtUtc: end,
      totalDurationMs: totalDurationMs,
      outcome: outcome,
      routineSnapshot: routineSnapshot,
      events: _eventsFor(breakdown, sessionId),
    );

    state = DraftSessionState(
      candidateSession: candidate,
      planBlockId: planBlockId,
      draftDurationMs: totalDurationMs,
      draftRoutineName: routineSnapshot.name,
      isVisible: true,
      isSaving: false,
      phaseBreakdown: breakdown,
    );
  }

  void adjustDuration(Duration delta) {
    final current = state.draftDurationMs;
    final target = (current + delta.inMilliseconds)
        .clamp(SessionValidator.minDurationMs, SessionValidator.maxDurationMs);
    final applied = target - current;

    final breakdown = state.phaseBreakdown;
    if (breakdown.isEmpty) {
      state = state.copyWith(draftDurationMs: target, clearValidationError: true);
      return;
    }

    // The delta lands on the last focus phase, so the focus time the user
    // sees is the one that moves. A session without a focus phase moves its
    // last phase instead.
    final index = _lastAdjustableIndex(breakdown);
    final entry = breakdown[index];
    final newDuration = math.max(0, entry.durationMs + applied);
    // What the phase could not absorb is dropped, so the total moves by
    // exactly what the phase took.
    final absorbed = newDuration - entry.durationMs;

    final updated = List<PhaseLedgerEntry>.of(breakdown);
    updated[index] = _withDuration(entry, newDuration);

    state = state.copyWith(
      phaseBreakdown: updated,
      draftDurationMs: current + absorbed,
      clearValidationError: true,
    );
  }

  /// The phase an adjustment lands on: the last focus phase, or the last
  /// phase when the session has none.
  int _lastAdjustableIndex(List<PhaseLedgerEntry> breakdown) {
    for (var i = breakdown.length - 1; i >= 0; i--) {
      if (breakdown[i].kind == PhaseKind.focus) return i;
    }
    return breakdown.length - 1;
  }

  PhaseLedgerEntry _withDuration(PhaseLedgerEntry entry, int durationMs) {
    return PhaseLedgerEntry(
      phaseId: entry.phaseId,
      phaseName: entry.phaseName,
      kind: entry.kind,
      phaseIndex: entry.phaseIndex,
      repeatIndex: entry.repeatIndex,
      durationMs: durationMs,
      outcome: entry.outcome,
      startedAtUtc: entry.startedAtUtc,
      endedAtUtc: entry.endedAtUtc,
    );
  }

  /// The session events of a breakdown: one event per phase, carrying the
  /// phase's kind and the active time it took.
  List<SessionEventRecord> _eventsFor(
    List<PhaseLedgerEntry> breakdown,
    String sessionId,
  ) {
    return breakdown
        .map((e) => SessionEventRecord(
              eventId: const Uuid().v4(),
              sessionId: sessionId,
              eventType: e.outcome == PhaseStatus.skipped
                  ? 'phase_skipped'
                  : 'phase_finished',
              occurredAtUtc: e.endedAtUtc,
              phaseId: e.phaseId,
              phaseName: e.phaseName,
              durationMs: e.durationMs,
              outcome: e.outcome.name,
              kind: e.kind,
            ))
        .toList(growable: false);
  }

  void setDurationMs(int durationMs) {
    final clamped = durationMs.clamp(
      SessionValidator.minDurationMs,
      SessionValidator.maxDurationMs,
    );
    state = state.copyWith(draftDurationMs: clamped, clearValidationError: true);
  }

  void setRoutineName(String name) {
    state = state.copyWith(draftRoutineName: name, clearValidationError: true);
  }

  Future<bool> confirmSave() async {
    final candidate = state.candidateSession;
    if (state.isSaving || candidate == null) return false;

    final trimmedName = state.draftRoutineName.trim();
    final finalDuration = state.draftDurationMs;
    final finalEnd = candidate.endedAtUtc;
    // The session keeps the run's real start: the wall-clock span is longer
    // than the active time whenever the run was paused, and the phases'
    // events must stay inside the session's window.
    final finalStart = candidate.startedAtUtc;
    // The stored events carry the adjusted breakdown, so the stored total
    // and the stored breakdown agree.
    final events = _eventsFor(state.phaseBreakdown, candidate.sessionId);

    final finalizedSession = SessionRecord(
      sessionId: candidate.sessionId,
      routineId: candidate.routineId,
      planBlockId: state.planBlockId,
      routineName: trimmedName,
      startedAtUtc: finalStart,
      endedAtUtc: finalEnd,
      totalDurationMs: finalDuration,
      outcome: candidate.outcome,
      routineSnapshot: candidate.routineSnapshot,
      events: events,
    );

    final validation = SessionValidator.validate(finalizedSession);
    if (!validation.isValid) {
      state = state.copyWith(
        validationError: validation.errors.map((e) => e.message).join(' '),
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearValidationError: true);
    try {
      await _sessionRepository.recordSession(finalizedSession);

      final blockId = state.planBlockId;
      if (blockId != null) {
        final planStatus = finalizedSession.outcome == SessionOutcome.completed
            ? PlanBlockStatus.completed
            : PlanBlockStatus.cancelled;
        await _planBlockRepository.linkSession(
          blockId: blockId,
          sessionId: finalizedSession.sessionId,
          actualDurationMs: finalizedSession.totalDurationMs,
          status: planStatus,
        );
      }

      _onSessionSaved?.call();
      state = const DraftSessionState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        validationError: 'Failed to save session: $e',
      );
      return false;
    }
  }

  Future<void> discard() async {
    final blockId = state.planBlockId;
    if (blockId != null) {
      await _revertPlanBlock(blockId);
    }
    state = const DraftSessionState();
  }

  Future<void> _revertPlanBlock(String blockId) async {
    try {
      final block = await _planBlockRepository.getBlockById(blockId);
      if (block != null) {
        await _planBlockRepository.updatePlanBlock(
          block.copyWith(status: PlanBlockStatus.scheduled),
        );
      }
    } catch (_) {}
  }
}
