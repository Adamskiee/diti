import 'dart:async';
import 'dart:math' as math;
import '../clock/cancelable_token.dart';
import '../clock/monotonic_clock.dart';
import '../clock/wall_clock.dart';
import '../domain/command_result.dart';
import '../domain/enums.dart';
import '../domain/timer_event.dart';
import '../domain/timer_run.dart';
import '../domain/timer_run_state.dart';
import '../ports/notification_port.dart';
import '../ports/routine_repository.dart';
import '../ports/run_persistence_port.dart';
import 'command_queue.dart';
import 'timer_engine.dart';

class TimerEngineImpl implements TimerEngine {
  final MonotonicClock monotonicClock;
  final WallClock wallClock;
  final RoutineRepository routineRepository;
  final RunPersistencePort persistencePort;
  final NotificationPort notificationPort;

  final CommandQueue _queue = CommandQueue();
  final StreamController<TimerRunState> _stateController =
      StreamController<TimerRunState>.broadcast();
  final StreamController<TimerEvent> _eventController =
      StreamController<TimerEvent>.broadcast();

  TimerRun? _activeRun;
  CancelableToken? _boundaryTimerToken;
  String? get activeRunId => _activeRun?.runId;

  TimerEngineImpl({
    required this.monotonicClock,
    required this.wallClock,
    required this.routineRepository,
    required this.persistencePort,
    required this.notificationPort,
  });

  @override
  Stream<TimerRunState> get stateStream => _stateController.stream;

  @override
  Stream<TimerEvent> get eventStream => _eventController.stream;

  @override
  TimerRunState? getState(String runId) {
    if (_activeRun?.runId != runId) return null;
    return _activeRun!.calculateState(currentMonotonicMs: monotonicClock.nowMs);
  }

  @override
  Future<Duration> elapsed(String runId) async {
    final state = getState(runId);
    if (state == null) return Duration.zero;
    return Duration(milliseconds: state.activeElapsedMs);
  }

  @override
  Future<TimerCommandResult> start(String routineId) => _queue.run(() async {
    final routine = await routineRepository.getRoutine(routineId);
    if (routine == null) {
      return const TimerCommandResult(
        success: false,
        error: TimerError.invalidConfiguration,
        stateVersion: 0,
      );
    }
    final configError = routine.validate();
    if (configError != null) {
      return TimerCommandResult(
        success: false,
        error: configError,
        stateVersion: 0,
      );
    }

    final snapshot = routine.clone();
    final nowUtc = wallClock.utcNow;
    final nowMono = monotonicClock.nowMs;
    final runId = 'run-${nowUtc.millisecondsSinceEpoch}';

    final run = TimerRun(
      runId: runId,
      routineSnapshot: snapshot,
      status: RunStatus.running,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: 0,
      repeatIndex: 0,
      accumulatedMs: 0,
      phaseStartedAtUtc: nowUtc,
      phaseStartedMonotonicMs: nowMono,
      stateVersion: 1,
    );

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runStarted,
      occurredAtUtc: nowUtc,
    );

    try {
      await persistencePort.persistRunAndEvents(run, [event]);
    } catch (_) {
      return const TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: 0,
      );
    }

    _activeRun = run;
    _scheduleBoundaryIfNeeded(run);
    _emitState(run);
    _eventController.add(event);

    return TimerCommandResult(success: true, stateVersion: run.stateVersion);
  });

  @override
  Future<TimerCommandResult> pause(String runId) => _queue.run(() async {
    if (_activeRun == null || _activeRun!.runId != runId) {
      return TimerCommandResult(
        success: false,
        error: TimerError.runNotFound,
        stateVersion: _activeRun?.stateVersion ?? 0,
      );
    }
    if (_activeRun!.status == RunStatus.paused) {
      // Idempotent no-op
      return TimerCommandResult(
        success: true,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    if (_activeRun!.status != RunStatus.running) {
      return TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    final nowMono = monotonicClock.nowMs;
    final nowUtc = wallClock.utcNow;
    final segmentElapsed =
        math.max(0, nowMono - (_activeRun!.phaseStartedMonotonicMs ?? nowMono));
    final newAccumulated = _activeRun!.accumulatedMs + segmentElapsed;

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.paused,
      accumulatedMs: newAccumulated,
      phaseStartedMonotonicMs: () => null,
      pausedAtUtc: () => nowUtc,
      stateVersion: _activeRun!.stateVersion + 1,
    );

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runPaused,
      occurredAtUtc: nowUtc,
      durationMs: segmentElapsed,
    );

    try {
      await persistencePort.persistRunAndEvents(updatedRun, [event]);
    } catch (_) {
      return TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    _boundaryTimerToken?.cancel();
    _activeRun = updatedRun;
    _emitState(updatedRun);
    _eventController.add(event);

    return TimerCommandResult(success: true, stateVersion: updatedRun.stateVersion);
  });

  @override
  Future<TimerCommandResult> resume(String runId) => _queue.run(() async {
    if (_activeRun == null || _activeRun!.runId != runId) {
      return TimerCommandResult(
        success: false,
        error: TimerError.runNotFound,
        stateVersion: _activeRun?.stateVersion ?? 0,
      );
    }
    if (_activeRun!.status != RunStatus.paused) {
      return TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    final nowMono = monotonicClock.nowMs;
    final nowUtc = wallClock.utcNow;

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.running,
      phaseStartedMonotonicMs: () => nowMono,
      pausedAtUtc: () => null,
      stateVersion: _activeRun!.stateVersion + 1,
    );

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runResumed,
      occurredAtUtc: nowUtc,
    );

    try {
      await persistencePort.persistRunAndEvents(updatedRun, [event]);
    } catch (_) {
      return TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    _activeRun = updatedRun;
    _scheduleBoundaryIfNeeded(updatedRun);
    _emitState(updatedRun);
    _eventController.add(event);

    return TimerCommandResult(success: true, stateVersion: updatedRun.stateVersion);
  });

  @override
  Future<TimerCommandResult> stop(String runId) => _queue.run(() async {
    if (_activeRun == null || _activeRun!.runId != runId) {
      return TimerCommandResult(
        success: false,
        error: TimerError.runNotFound,
        stateVersion: _activeRun?.stateVersion ?? 0,
      );
    }
    if (_activeRun!.status == RunStatus.cancelled) {
      return TimerCommandResult(
        success: true,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    if (_activeRun!.status != RunStatus.running &&
        _activeRun!.status != RunStatus.paused) {
      return TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    final nowMono = monotonicClock.nowMs;
    final nowUtc = wallClock.utcNow;
    final segmentElapsed = _activeRun!.status == RunStatus.running
        ? math.max(0, nowMono - (_activeRun!.phaseStartedMonotonicMs ?? nowMono))
        : 0;
    final newAccumulated = _activeRun!.accumulatedMs + segmentElapsed;

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.cancelled,
      accumulatedMs: newAccumulated,
      phaseStartedMonotonicMs: () => null,
      stateVersion: _activeRun!.stateVersion + 1,
    );

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runCancelled,
      occurredAtUtc: nowUtc,
    );

    try {
      await persistencePort.persistRunAndEvents(updatedRun, [event]);
      await notificationPort.cancelBoundaries(runId);
    } catch (_) {
      return TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    _boundaryTimerToken?.cancel();
    _activeRun = updatedRun;
    _emitState(updatedRun);
    _eventController.add(event);

    return TimerCommandResult(success: true, stateVersion: updatedRun.stateVersion);
  });

  void _scheduleBoundaryIfNeeded(TimerRun run) {
    _boundaryTimerToken?.cancel();
    final phase = run.currentPhase;
    if (phase.durationMs == null || phase.transition != TransitionPolicy.auto) {
      return;
    }

    final remainingMs = math.max(0, phase.durationMs! - run.accumulatedMs);
    final expectedUtc =
        wallClock.utcNow.add(Duration(milliseconds: remainingMs));
    notificationPort.scheduleBoundaryNotification(
      runId: run.runId,
      phaseId: phase.id,
      phaseName: phase.name,
      expectedUtc: expectedUtc,
    );

    _boundaryTimerToken = monotonicClock.schedule(
      Duration(milliseconds: remainingMs),
      () => _onBoundaryReached(run.runId, run.stateVersion),
    );
  }

  void _onBoundaryReached(String runId, int expectedVersion) {
    // Overridden/expanded in Task 8
  }

  void _emitState(TimerRun run) {
    _stateController
        .add(run.calculateState(currentMonotonicMs: monotonicClock.nowMs));
  }

  // Placeholder methods completed in Task 8 & 9
  @override
  Future<TimerCommandResult> skipPhase(String runId) async =>
      const TimerCommandResult(success: true, stateVersion: 1);

  @override
  Future<TimerCommandResult> finishPhase(String runId) async =>
      const TimerCommandResult(success: true, stateVersion: 1);

  @override
  Future<TimerCommandResult> finishRun(String runId) async =>
      const TimerCommandResult(success: true, stateVersion: 1);

  @override
  Future<void> recover() async {}
}
