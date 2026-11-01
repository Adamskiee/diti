import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/repositories_provider.dart';
import '../../domain/manual_session_state.dart';
import '../../providers/history_providers.dart';
import '../../../plan/providers/plan_providers.dart';

class ManualSessionController extends StateNotifier<ManualSessionState> {
  final SessionRepository _sessionRepository;
  final PlanBlockRepository _planBlockRepository;
  final ActivityJournalRepository _journalRepository;
  final Ref _ref;
  int _usageSeq = 0;

  ManualSessionController({
    required SessionRepository sessionRepository,
    required PlanBlockRepository planBlockRepository,
    required ActivityJournalRepository journalRepository,
    required Ref ref,
    DateTime? initialDate,
    TimeOfDay? initialStartTime,
    int? initialDurationMinutes,
    String? initialRoutineName,
    String? initialRoutineId,
    String? initialPlanBlockId,
  })  : _sessionRepository = sessionRepository,
        _planBlockRepository = planBlockRepository,
        _journalRepository = journalRepository,
        _ref = ref,
        super(_createInitialState(
          initialDate,
          initialStartTime,
          initialDurationMinutes,
          initialRoutineName,
          initialRoutineId,
          initialPlanBlockId,
        )) {
    refreshUsage();
  }

  static ManualSessionState _createInitialState(
    DateTime? date,
    TimeOfDay? start,
    int? duration,
    String? routine,
    String? routineId,
    String? planBlockId,
  ) {
    final now = DateTime.now();
    final sDate = date ?? DateTime(now.year, now.month, now.day);
    final sStart = start ?? TimeOfDay(hour: (now.hour - 1 + 24) % 24, minute: 0);
    final dur = duration ?? 30;
    final totalStartMin = sStart.hour * 60 + sStart.minute;
    final totalEndMin = (totalStartMin + dur) % (24 * 60);
    final sEnd = TimeOfDay(hour: totalEndMin ~/ 60, minute: totalEndMin % 60);

    return ManualSessionState(
      selectedDate: sDate,
      startTime: sStart,
      endTime: sEnd,
      durationMinutes: dur,
      routineName: routine ?? '',
      routineId: routineId,
      planBlockId: planBlockId,
    );
  }

  DateTime get _startUtc {
    final d = state.selectedDate;
    final local = DateTime(
      d.year,
      d.month,
      d.day,
      state.startTime.hour,
      state.startTime.minute,
    );
    return local.toUtc();
  }

  DateTime get _endUtc {
    return _startUtc.add(Duration(minutes: state.durationMinutes));
  }

  void setDate(DateTime date) {
    if (!mounted) return;
    state = state.copyWith(selectedDate: date);
    refreshUsage();
  }

  void setStartTime(TimeOfDay time) {
    if (!mounted) return;
    final startMin = time.hour * 60 + time.minute;
    var endMin = state.endTime.hour * 60 + state.endTime.minute;
    if (endMin < startMin) endMin += 24 * 60;
    final diff = endMin - startMin;
    state = state.copyWith(startTime: time, durationMinutes: diff > 0 ? diff : 30);
    refreshUsage();
  }

  void setEndTime(TimeOfDay time) {
    if (!mounted) return;
    final startMin = state.startTime.hour * 60 + state.startTime.minute;
    var endMin = time.hour * 60 + time.minute;
    if (endMin < startMin) endMin += 24 * 60;
    final diff = endMin - startMin;
    state = state.copyWith(endTime: time, durationMinutes: diff > 0 ? diff : 30);
    refreshUsage();
  }

  void setDurationMinutes(int minutes) {
    if (!mounted) return;
    if (minutes <= 0) return;
    final startMin = state.startTime.hour * 60 + state.startTime.minute;
    final endTotal = (startMin + minutes) % (24 * 60);
    state = state.copyWith(
      durationMinutes: minutes,
      endTime: TimeOfDay(hour: endTotal ~/ 60, minute: endTotal % 60),
    );
    refreshUsage();
  }

  void setRoutineName(String name, {String? routineId}) {
    if (!mounted) return;
    state = state.copyWith(
      routineName: name,
      routineId: routineId,
      clearRoutineId: routineId == null,
    );
  }

  void setPlanBlockId(String? planBlockId) {
    if (!mounted) return;
    state = state.copyWith(
      planBlockId: planBlockId,
      clearPlanBlockId: planBlockId == null,
    );
  }

  Future<void> refreshUsage() async {
    final seq = ++_usageSeq;
    if (!mounted) return;
    state = state.copyWith(isLoadingUsage: true);
    try {
      final usages = await _journalRepository.aggregateUsageBetween(_startUtc, _endUtc);
      if (!mounted) return;
      if (seq == _usageSeq) {
        state = state.copyWith(detectedAppUsages: usages, isLoadingUsage: false);
      }
    } catch (_) {
      if (!mounted) return;
      if (seq == _usageSeq) {
        state = state.copyWith(isLoadingUsage: false);
      }
    }
  }

  Future<bool> saveSession() async {
    final title = state.routineName.trim();
    if (title.isEmpty) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: 'Please enter an activity name.');
      return false;
    }

    final durationMs = state.durationMinutes * 60 * 1000;
    if (durationMs < 1000) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: 'Session duration must be at least 1 minute.');
      return false;
    }

    if (!mounted) return false;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final sessionId = const Uuid().v4();
      final start = _startUtc;
      final end = start.add(Duration(milliseconds: durationMs));

      final syntheticRoutine = Routine(
        id: state.routineId ?? const Uuid().v4(),
        name: title,
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: const Uuid().v4(),
            name: title,
            durationMs: durationMs,
            transition: TransitionPolicy.manual,
            kind: PhaseKind.focus,
          ),
        ],
      );

      final session = SessionRecord(
        sessionId: sessionId,
        routineId: state.routineId ?? syntheticRoutine.id,
        planBlockId: state.planBlockId,
        routineName: title,
        startedAtUtc: start,
        endedAtUtc: end,
        totalDurationMs: durationMs,
        outcome: SessionOutcome.completed,
        routineSnapshot: syntheticRoutine,
        events: [
          SessionEventRecord(
            eventId: const Uuid().v4(),
            sessionId: sessionId,
            eventType: 'phase_started',
            phaseName: title,
            kind: PhaseKind.focus,
            occurredAtUtc: start,
          ),
          SessionEventRecord(
            eventId: const Uuid().v4(),
            sessionId: sessionId,
            eventType: 'phase_finished',
            phaseName: title,
            kind: PhaseKind.focus,
            occurredAtUtc: end,
            durationMs: durationMs,
          ),
        ],
        appUsages: state.detectedAppUsages
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

      await _sessionRepository.saveSession(session);

      if (state.planBlockId != null) {
        final existingBlock = await _planBlockRepository.getBlockById(state.planBlockId!);
        if (existingBlock != null) {
          await _planBlockRepository.updatePlanBlock(
            existingBlock.copyWith(
              status: PlanBlockStatus.completed,
              actualDurationMs: durationMs,
              sessionId: sessionId,
            ),
          );
        }
      }

      // Refresh screens
      _ref.invalidate(historyFeedControllerProvider);
      _ref.invalidate(analyticsControllerProvider);
      try {
        _ref.read(dailyPlanControllerProvider.notifier).refresh();
      } catch (_) {}

      if (!mounted) return true;
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save session: $e');
      return false;
    }
  }
}

final manualSessionControllerProvider =
    StateNotifierProvider.autoDispose<ManualSessionController, ManualSessionState>((ref) {
  return ManualSessionController(
    sessionRepository: ref.watch(sessionRepositoryProvider),
    planBlockRepository: ref.watch(planBlockRepositoryProvider),
    journalRepository: ref.watch(activityJournalRepositoryProvider),
    ref: ref,
  );
});
