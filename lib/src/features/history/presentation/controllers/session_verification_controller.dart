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
    final activeDurationMs = runState.activeElapsedMs;

    // Noise filter: prune cancelled micro-sessions < 60s
    if (runState.status == RunStatus.cancelled &&
        activeDurationMs < minNoiseDurationMs) {
      if (planBlockId != null) {
        await _revertPlanBlock(planBlockId);
      }
      state = const DraftSessionState();
      return;
    }

    final end = nowUtc ?? DateTime.now().toUtc();
    final start = end.subtract(Duration(milliseconds: activeDurationMs));
    final outcome = runState.status == RunStatus.completed
        ? SessionOutcome.completed
        : SessionOutcome.cancelled;

    final candidate = SessionRecord(
      sessionId: const Uuid().v4(),
      routineId: routineSnapshot.id,
      planBlockId: planBlockId,
      routineName: routineSnapshot.name,
      startedAtUtc: start,
      endedAtUtc: end,
      totalDurationMs: activeDurationMs,
      outcome: outcome,
      routineSnapshot: routineSnapshot,
    );

    state = DraftSessionState(
      candidateSession: candidate,
      planBlockId: planBlockId,
      draftDurationMs: activeDurationMs,
      draftRoutineName: routineSnapshot.name,
      isVisible: true,
      isSaving: false,
    );
  }

  void adjustDuration(Duration delta) {
    final current = state.draftDurationMs;
    final updated = (current + delta.inMilliseconds)
        .clamp(SessionValidator.minDurationMs, SessionValidator.maxDurationMs);
    state = state.copyWith(draftDurationMs: updated, clearValidationError: true);
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
    if (candidate == null) return false;

    final trimmedName = state.draftRoutineName.trim();
    final finalDuration = state.draftDurationMs;
    final finalEnd = candidate.startedAtUtc.add(Duration(milliseconds: finalDuration));

    final finalizedSession = SessionRecord(
      sessionId: candidate.sessionId,
      routineId: candidate.routineId,
      planBlockId: state.planBlockId,
      routineName: trimmedName,
      startedAtUtc: candidate.startedAtUtc,
      endedAtUtc: finalEnd,
      totalDurationMs: finalDuration,
      outcome: candidate.outcome,
      routineSnapshot: candidate.routineSnapshot,
      events: candidate.events,
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
