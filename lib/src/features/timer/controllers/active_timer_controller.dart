import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../core/di/timer_engine_provider.dart';
import '../../../core/utils/duration_formatter.dart';
import '../domain/timer_display_state.dart';

class ActiveTimerController extends Notifier<TimerDisplayState> {
  Timer? _ticker;
  StreamSubscription<TimerRunState>? _engineSub;

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

  Future<TimerCommandResult> startRoutine(String routineId) async {
    final engine = ref.read(timerEngineProvider);
    final res = await engine.start(routineId);
    if (res.success && engine.activeRunId != null) {
      final s = engine.getState(engine.activeRunId!);
      if (s != null) {
        _syncState(s);
      }
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
      } else {
        state = TimerDisplayState(
          runId: runId,
          status: RunStatus.cancelled,
          phaseName: state.phaseName,
        );
        _stopTicker();
      }
    }
    return res;
  }
}

final activeTimerControllerProvider =
    NotifierProvider<ActiveTimerController, TimerDisplayState>(
  ActiveTimerController.new,
);
