import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/repositories_provider.dart';
import '../../../core/di/timer_engine_provider.dart';
import '../../../core/utils/duration_formatter.dart';
import '../domain/timer_display_state.dart';

class ActiveTimerController extends Notifier<TimerDisplayState> {
  Timer? _ticker;
  StreamSubscription<TimerRunState>? _engineSub;
  String? _activePlanBlockId;
  Future<void>? _linkingSessionFuture;

  @override
  TimerDisplayState build() {
    final engine = ref.watch(timerEngineProvider);
    _engineSub?.cancel();
    _engineSub = engine.stateStream.listen(_onEngineState);
    ref.onDispose(() {
      _ticker?.cancel();
      _engineSub?.cancel();
    });

    final currentRunId = engine.activeRunId;
    if (currentRunId != null) {
      final s = engine.getState(currentRunId);
      if (s != null) {
        if (s.status == RunStatus.running) {
          _startTicker();
        }
        return _mapFromRunState(s);
      }
    }
    return const TimerDisplayState();
  }

  void _onEngineState(TimerRunState runState) {
    _syncState(runState);
    if (runState.status == RunStatus.completed ||
        runState.status == RunStatus.cancelled) {
      unawaited(_checkAndLinkSession(runState).catchError((_) {}));
    }
  }

  void _syncState(TimerRunState runState) {
    state = _mapFromRunState(runState);
    if (runState.status == RunStatus.running) {
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void tick() {
    final runId = state.runId;
    if (runId == null || state.status != RunStatus.running) return;

    final engine = ref.read(timerEngineProvider);
    final runState = engine.getState(runId);
    if (runState != null) {
      state = _mapFromRunState(runState);
      if (runState.status != RunStatus.running) {
        _stopTicker();
      }
    }
  }

  TimerDisplayState _mapFromRunState(TimerRunState s) {
    final duration = s.currentPhase.durationMs;
    final isCountdown = duration != null;

    final int remainingMs;
    final int elapsedMs;
    final double progress;

    if (isCountdown) {
      remainingMs = s.remainingMs ?? (duration - s.activeElapsedMs);
      elapsedMs = s.activeElapsedMs;
      progress = duration > 0 ? (remainingMs / duration).clamp(0.0, 1.0) : 0.0;
    } else {
      remainingMs = 0;
      elapsedMs = s.activeElapsedMs;
      progress = 1.0;
    }

    final formatted = isCountdown
        ? DurationFormatter.formatMs(remainingMs)
        : DurationFormatter.formatMs(elapsedMs);

    final engine = ref.read(timerEngineProvider);
    final activeRun = engine.getActiveRun();
    String? nextPhase;
    if (activeRun != null && activeRun.runId == s.runId) {
      final phases = activeRun.routineSnapshot.phases;
      if (s.currentPhaseIndex + 1 < phases.length) {
        nextPhase = phases[s.currentPhaseIndex + 1].name;
      } else {
        final repeatRule = activeRun.routineSnapshot.repeatRule;
        if (repeatRule.mode == RepeatMode.forever ||
            s.repeatIndex < repeatRule.count - 1) {
          if (phases.isNotEmpty) {
            nextPhase = phases.first.name;
          }
        }
      }
    }

    return TimerDisplayState(
      runId: s.runId,
      planBlockId: _activePlanBlockId,
      status: s.status,
      phaseStatus: s.phaseStatus,
      phaseName: s.phaseName,
      isCountdown: isCountdown,
      displayRemainingMs: remainingMs,
      displayElapsedMs: elapsedMs,
      progress: progress,
      formattedTime: formatted,
      cycleDescription:
          'Repetition ${s.currentRepetition} · Phase ${s.currentPhaseIndex + 1}',
      nextPhasePreview: nextPhase,
    );
  }

  Future<void> _checkAndLinkSession(TimerRunState runState) {
    if (_linkingSessionFuture != null) {
      return _linkingSessionFuture!;
    }
    final blockId = _activePlanBlockId;
    if (blockId == null) return Future.value();
    _activePlanBlockId = null;

    final completer = Completer<void>();
    _linkingSessionFuture = completer.future;

    () async {
      try {
        final planRepo = ref.read(planBlockRepositoryProvider);
        final sessionRepo = ref.read(sessionRepositoryProvider);

        SessionRecord? session;
        try {
          session = await sessionRepo.getSession(runState.runId);
        } catch (_) {}

        if (session == null) {
          try {
            final blockSessions =
                await sessionRepo.getSessionsForPlanBlock(blockId);
            if (blockSessions.isNotEmpty) {
              session = blockSessions.last;
            }
          } catch (_) {}
        }

        final actualDurationMs =
            session?.totalDurationMs ?? runState.activeElapsedMs;
        final sessionId = session?.sessionId ?? runState.runId;
        final status = runState.status == RunStatus.completed
            ? PlanBlockStatus.completed
            : PlanBlockStatus.cancelled;

        await planRepo.linkSession(
          blockId: blockId,
          sessionId: sessionId,
          actualDurationMs: actualDurationMs,
          status: status,
        );
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _linkingSessionFuture = null;
      }
    }();

    return completer.future;
  }

  Future<TimerCommandResult> startRoutine(
    String routineIdOrName, {
    String? planBlockId,
    String? customTitle,
  }) async {
    _activePlanBlockId = planBlockId;
    _linkingSessionFuture = null;
    PlanBlock? linkedBlock;

    if (planBlockId != null) {
      final planRepo = ref.read(planBlockRepositoryProvider);
      final block = await planRepo.getBlockById(planBlockId);
      if (block != null) {
        linkedBlock = block;
        await planRepo.updatePlanBlock(
          block.copyWith(status: PlanBlockStatus.inProgress),
        );
      }
    }

    // Resolve routine
    final routineRepo = ref.read(routineRepositoryProvider);
    String resolvedRoutineId = routineIdOrName;
    final existingById = await routineRepo.getRoutine(routineIdOrName);
    if (existingById != null) {
      resolvedRoutineId = existingById.id;
    } else {
      final allRoutines = await routineRepo.getAllRoutines();
      final matchingByName =
          allRoutines.where((r) => r.name == routineIdOrName).firstOrNull;
      if (matchingByName != null) {
        resolvedRoutineId = matchingByName.id;
      } else {
        // Custom activity: create and persist a single-phase routine
        final newRoutineId = const Uuid().v4();
        final activityName = customTitle ?? routineIdOrName;
        final newRoutine = Routine(
          id: newRoutineId,
          name: activityName,
          repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
          phases: [
            RoutinePhase(
              id: const Uuid().v4(),
              name: activityName,
              durationMs: linkedBlock?.plannedDurationMs ?? 1500000,
              transition: TransitionPolicy.manual,
            ),
          ],
        );
        await routineRepo.saveRoutine(newRoutine);
        resolvedRoutineId = newRoutineId;
      }
    }

    final engine = ref.read(timerEngineProvider);
    final res = await engine.start(resolvedRoutineId);
    if (res.success && engine.activeRunId != null) {
      final s = engine.getState(engine.activeRunId!);
      if (s != null) {
        _syncState(s);
      }
    } else if (!res.success) {
      if (linkedBlock != null) {
        final planRepo = ref.read(planBlockRepositoryProvider);
        await planRepo.updatePlanBlock(
          linkedBlock.copyWith(status: PlanBlockStatus.scheduled),
        );
      }
      _activePlanBlockId = null;
    }
    return res;
  }

  Future<TimerCommandResult> pause() async {
    final runId = state.runId ?? ref.read(timerEngineProvider).activeRunId;
    if (runId == null) {
      return const TimerCommandResult(success: false, stateVersion: 0);
    }
    final res = await ref.read(timerEngineProvider).pause(runId);
    if (res.success) {
      final s = ref.read(timerEngineProvider).getState(runId);
      if (s != null) {
        _syncState(s);
      }
    }
    return res;
  }

  Future<TimerCommandResult> resume() async {
    final runId = state.runId ?? ref.read(timerEngineProvider).activeRunId;
    if (runId == null) {
      return const TimerCommandResult(success: false, stateVersion: 0);
    }
    final res = await ref.read(timerEngineProvider).resume(runId);
    if (res.success) {
      final s = ref.read(timerEngineProvider).getState(runId);
      if (s != null) {
        _syncState(s);
      }
    }
    return res;
  }

  Future<TimerCommandResult> skipPhase() async {
    final runId = state.runId ?? ref.read(timerEngineProvider).activeRunId;
    if (runId == null) {
      return const TimerCommandResult(success: false, stateVersion: 0);
    }
    final res = await ref.read(timerEngineProvider).skipPhase(runId);
    if (res.success) {
      final s = ref.read(timerEngineProvider).getState(runId);
      if (s != null) {
        _syncState(s);
      }
    }
    return res;
  }

  Future<TimerCommandResult> finishPhase() async {
    final runId = state.runId ?? ref.read(timerEngineProvider).activeRunId;
    if (runId == null) {
      return const TimerCommandResult(success: false, stateVersion: 0);
    }
    final res = await ref.read(timerEngineProvider).finishPhase(runId);
    if (res.success) {
      final s = ref.read(timerEngineProvider).getState(runId);
      if (s != null) {
        _syncState(s);
        if (s.status == RunStatus.completed ||
            s.status == RunStatus.cancelled) {
          await _checkAndLinkSession(s);
        }
      }
    }
    return res;
  }

  Future<TimerCommandResult> finishRun() async {
    final runId = state.runId ?? ref.read(timerEngineProvider).activeRunId;
    if (runId == null) {
      return const TimerCommandResult(success: false, stateVersion: 0);
    }
    final res = await ref.read(timerEngineProvider).finishRun(runId);
    if (res.success) {
      final s = ref.read(timerEngineProvider).getState(runId);
      if (s != null) {
        _syncState(s);
        if (s.status == RunStatus.completed ||
            s.status == RunStatus.cancelled) {
          await _checkAndLinkSession(s);
        }
      }
    }
    return res;
  }

  Future<TimerCommandResult> stop() async {
    final runId = state.runId ?? ref.read(timerEngineProvider).activeRunId;
    if (runId == null) {
      return const TimerCommandResult(success: false, stateVersion: 0);
    }
    final res = await ref.read(timerEngineProvider).stop(runId);
    if (res.success) {
      final s = ref.read(timerEngineProvider).getState(runId);
      if (s != null) {
        _syncState(s);
        await _checkAndLinkSession(s);
      } else {
        final cancelledRunState = TimerRunState(
          runId: runId,
          status: RunStatus.cancelled,
          phaseStatus: PhaseStatus.active,
          currentPhase: RoutinePhase(
            id: 'unknown',
            name: state.phaseName,
            transition: TransitionPolicy.manual,
          ),
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: state.displayElapsedMs,
          stateVersion: 0,
        );
        state = TimerDisplayState(
          runId: runId,
          planBlockId: _activePlanBlockId,
          status: RunStatus.cancelled,
          phaseName: state.phaseName,
        );
        _stopTicker();
        await _checkAndLinkSession(cancelledRunState);
      }
    }
    return res;
  }
}

final activeTimerControllerProvider =
    NotifierProvider<ActiveTimerController, TimerDisplayState>(
  ActiveTimerController.new,
);
