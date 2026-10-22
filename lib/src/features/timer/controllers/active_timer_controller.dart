import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/repositories_provider.dart';
import '../../../core/di/timer_engine_provider.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../history/providers/history_providers.dart';
import '../domain/timer_display_state.dart';

class ActiveTimerController extends Notifier<TimerDisplayState> {
  Timer? _ticker;
  StreamSubscription<TimerRunState>? _engineSub;
  String? _activePlanBlockId;
  Future<void>? _verificationFuture;
  String? _handledVerificationRunId;

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
      unawaited(_delegateVerification(runState));
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
    final isEnded =
        s.status == RunStatus.completed || s.status == RunStatus.cancelled;
    // An ended run keeps the time of the phase that just ended in the
    // ledger, not in the accumulator, so the dial is read from there.
    final phaseElapsedMs = isEnded && s.completedPhases.isNotEmpty
        ? s.completedPhases.last.durationMs
        : s.activeElapsedMs;

    final int remainingMs;
    final int elapsedMs;
    final double progress;

    if (isCountdown) {
      remainingMs = _remainingMs(s, duration, phaseElapsedMs);
      elapsedMs = phaseElapsedMs;
      progress = duration > 0 ? (remainingMs / duration).clamp(0.0, 1.0) : 0.0;
    } else {
      remainingMs = 0;
      elapsedMs = phaseElapsedMs;
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

  /// The time the dial counts down.
  ///
  /// An ended run keeps the time of the phase that just ended in the ledger,
  /// not in the accumulator: a finished phase has nothing left to run, a
  /// cancelled one shows what was left of it.
  int _remainingMs(TimerRunState s, int duration, int phaseElapsedMs) {
    if (s.status == RunStatus.completed) return 0;
    if (s.status == RunStatus.cancelled) {
      return duration > phaseElapsedMs ? duration - phaseElapsedMs : 0;
    }
    return s.remainingMs ?? (duration - s.activeElapsedMs);
  }

  Future<void> _delegateVerification(TimerRunState runState) {
    if (_handledVerificationRunId == runState.runId &&
        _verificationFuture != null) {
      return _verificationFuture!;
    }
    _handledVerificationRunId = runState.runId;

    final engine = ref.read(timerEngineProvider);
    final phaseName = state.phaseName;
    final untrackedPhaseName = phaseName.isEmpty ? 'Focus' : phaseName;
    final routineSnapshot = engine.getActiveRun()?.routineSnapshot ??
        Routine(
          id: 'untracked',
          name: phaseName.isEmpty ? 'Focus Session' : phaseName,
          repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
          phases: [
            RoutinePhase(
              id: 'p1',
              name: untrackedPhaseName,
              transition: TransitionPolicy.manual,
              // The phase is synthesised, so its kind is seeded from its name -
              // the same rule the editor follows for a new phase.
              kind: PhaseKind.inferFromName(untrackedPhaseName),
            ),
          ],
        );

    final planBlockId = _activePlanBlockId;
    _activePlanBlockId = null;

    final future = ref
        .read(sessionVerificationControllerProvider.notifier)
        .prepareVerification(
          runState: runState,
          routineSnapshot: routineSnapshot,
          planBlockId: planBlockId,
        )
        .catchError((_) {});

    _verificationFuture = future;
    return future;
  }

  Future<TimerCommandResult> startRoutine(
    String routineIdOrName, {
    String? planBlockId,
    String? customTitle,
  }) async {
    _activePlanBlockId = planBlockId;
    _handledVerificationRunId = null;
    _verificationFuture = null;
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
              // A custom activity is a routine the app synthesises, so its
              // kind is seeded from the name: "Email cleanup" is focus,
              // "Coffee Break" is rest.
              kind: PhaseKind.inferFromName(activityName),
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
          await _delegateVerification(s);
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
          await _delegateVerification(s);
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
        await _delegateVerification(s);
      } else {
        // The engine no longer holds the run: the state is built by hand, so
        // it has to carry the time the phase had run. Without it the session
        // would come out empty and be discarded by the noise filter.
        final phase = RoutinePhase(
          id: 'unknown',
          name: state.phaseName,
          transition: TransitionPolicy.manual,
          // The phase is gone, but its name still says what kind of time it
          // was: the engine's own rule for that.
          kind: PhaseKind.inferFromName(state.phaseName),
        );
        final elapsedMs = state.displayElapsedMs;
        final nowUtc = ref.read(wallClockProvider).utcNow;
        // The run's start is not known any more, so it is reconstructed from
        // the time the phase had run.
        final startedAtUtc = nowUtc.subtract(Duration(milliseconds: elapsedMs));
        final cancelledRunState = TimerRunState(
          runId: runId,
          status: RunStatus.cancelled,
          phaseStatus: PhaseStatus.active,
          currentPhase: phase,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: elapsedMs,
          stateVersion: 0,
          completedPhases: [
            PhaseLedgerEntry(
              phaseId: phase.id,
              phaseName: phase.name,
              kind: phase.kind,
              phaseIndex: 0,
              repeatIndex: 0,
              durationMs: elapsedMs,
              outcome: PhaseStatus.finished,
              startedAtUtc: startedAtUtc,
              endedAtUtc: nowUtc,
            ),
          ],
          totalActiveElapsedMs: elapsedMs,
          runStartedAtUtc: startedAtUtc,
        );
        state = TimerDisplayState(
          runId: runId,
          planBlockId: _activePlanBlockId,
          status: RunStatus.cancelled,
          phaseName: state.phaseName,
        );
        _stopTicker();
        await _delegateVerification(cancelledRunState);
      }
    }
    return res;
  }
}

final activeTimerControllerProvider =
    NotifierProvider<ActiveTimerController, TimerDisplayState>(
  ActiveTimerController.new,
);
