import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';
import '../../domain/draft_session.dart';

class SessionVerificationController extends StateNotifier<DraftSessionState> {
  final SessionRepository _sessionRepository;
  final PlanBlockRepository _planBlockRepository;
  final void Function()? _onSessionSaved;
  String? _currentRunId;
  final Set<String> _handledRunIds = <String>{};

  SessionVerificationController({
    required SessionRepository sessionRepository,
    required PlanBlockRepository planBlockRepository,
    void Function()? onSessionSaved,
  })  : _sessionRepository = sessionRepository,
        _planBlockRepository = planBlockRepository,
        _onSessionSaved = onSessionSaved,
        super(const DraftSessionState());

  Future<void> prepareVerification({
    required TimerRunState runState,
    required Routine routineSnapshot,
    String? planBlockId,
    DateTime? nowUtc,
    List<AppUsageSummary> appUsages = const [],
  }) async {
    if (_handledRunIds.contains(runState.runId) || state.isSaving) {
      return;
    }
    _handledRunIds.add(runState.runId);
    _currentRunId = runState.runId;
    // The run's total active time: every phase that ended plus the phase
    // that was running. Never the current phase alone — that would drop the
    // focus time of a run that was cancelled during its break.
    final totalDurationMs = runState.totalActiveElapsedMs;
    final breakdown = List<PhaseLedgerEntry>.of(runState.completedPhases);

    // Prune runs without measurable time (< 1s) — such a session cannot be
    // saved at all — and every run whose ledger was lost. A session with a
    // total but no phases would break the rule that the total is the sum of
    // the phases.
    final hasNoMeasurableTime =
        totalDurationMs < SessionValidator.minDurationMs;
    if (hasNoMeasurableTime || breakdown.isEmpty) {
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
    // Any session saved to analytics via verification is marked completed,
    // including routines that were stopped early.
    const outcome = SessionOutcome.completed;

    final sessionId = const Uuid().v4();

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
      appUsages: appUsages
          .map((u) => SessionAppUsageRecord(
                id: const Uuid().v4(),
                sessionId: sessionId,
                appName: u.appName,
                category: u.category,
                sampleTitle: u.sampleTitle,
                durationMs: u.durationMs,
              ))
          .toList(growable: false),
    );

    state = DraftSessionState(
      candidateSession: candidate,
      planBlockId: planBlockId,
      draftDurationMs: totalDurationMs,
      draftRoutineName: routineSnapshot.name,
      isVisible: true,
      isSaving: false,
      phaseBreakdown: breakdown,
      appUsages: appUsages,
    );
  }

  void setAppUsages(List<AppUsageSummary> appUsages) {
    final candidate = state.candidateSession;
    final updatedCandidate = candidate != null
        ? SessionRecord(
            sessionId: candidate.sessionId,
            routineId: candidate.routineId,
            planBlockId: candidate.planBlockId,
            routineName: candidate.routineName,
            startedAtUtc: candidate.startedAtUtc,
            endedAtUtc: candidate.endedAtUtc,
            totalDurationMs: candidate.totalDurationMs,
            outcome: candidate.outcome,
            routineSnapshot: candidate.routineSnapshot,
            events: candidate.events,
            appUsages: appUsages
                .map((u) => SessionAppUsageRecord(
                      id: const Uuid().v4(),
                      sessionId: candidate.sessionId,
                      appName: u.appName,
                      category: u.category,
                      sampleTitle: u.sampleTitle,
                      durationMs: u.durationMs,
                    ))
                .toList(growable: false),
          )
        : null;
    state = state.copyWith(
      appUsages: appUsages,
      candidateSession: updatedCandidate ?? candidate,
    );
  }

  void adjustDuration(Duration delta) {
    final target = (state.draftDurationMs + delta.inMilliseconds)
        .clamp(SessionValidator.minDurationMs, SessionValidator.maxDurationMs);
    _applyTotal(target);
  }

  void setDurationMs(int durationMs) {
    final target = durationMs
        .clamp(SessionValidator.minDurationMs, SessionValidator.maxDurationMs);
    _applyTotal(target);
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
    final appUsageRecords = state.appUsages
        .map((u) => SessionAppUsageRecord(
              id: const Uuid().v4(),
              sessionId: candidate.sessionId,
              appName: u.appName,
              category: u.category,
              sampleTitle: u.sampleTitle,
              durationMs: u.durationMs,
            ))
        .toList(growable: false);

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
      appUsages: appUsageRecords,
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

      if (_currentRunId != null) {
        _handledRunIds.add(_currentRunId!);
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
    if (_currentRunId != null) {
      _handledRunIds.add(_currentRunId!);
    }
    state = const DraftSessionState();
  }

  /// Moves the session's total to [target] and lets the last focus phase
  /// absorb the difference, so the total and the breakdown always agree.
  void _applyTotal(int target) {
    final current = state.draftDurationMs;
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
