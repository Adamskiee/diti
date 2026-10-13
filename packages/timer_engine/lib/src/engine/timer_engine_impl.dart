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
    if (_activeRun != null &&
        (_activeRun!.status == RunStatus.running ||
            _activeRun!.status == RunStatus.paused)) {
      return TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: _activeRun!.stateVersion,
      );
    }

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

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runStarted,
      occurredAtUtc: nowUtc,
    );

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
      lastEventId: event.eventId,
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

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runPaused,
      occurredAtUtc: nowUtc,
      durationMs: segmentElapsed,
    );

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.paused,
      accumulatedMs: newAccumulated,
      phaseStartedMonotonicMs: () => null,
      pausedAtUtc: () => nowUtc,
      stateVersion: _activeRun!.stateVersion + 1,
      lastEventId: () => event.eventId,
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

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runResumed,
      occurredAtUtc: nowUtc,
    );

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.running,
      phaseStartedMonotonicMs: () => nowMono,
      pausedAtUtc: () => null,
      stateVersion: _activeRun!.stateVersion + 1,
      lastEventId: () => event.eventId,
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

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runCancelled,
      occurredAtUtc: nowUtc,
    );

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.cancelled,
      accumulatedMs: newAccumulated,
      phaseStartedMonotonicMs: () => null,
      stateVersion: _activeRun!.stateVersion + 1,
      lastEventId: () => event.eventId,
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
    if (run.status != RunStatus.running) return;
    if (run.phaseStatus == PhaseStatus.awaitingAction) return;

    final phase = run.currentPhase;
    if (phase.durationMs == null) {
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
    if (_activeRun == null || _activeRun!.runId != runId) return;
    if (_activeRun!.status != RunStatus.running) return;
    if (_activeRun!.stateVersion != expectedVersion) return;

    final currentPhase = _activeRun!.currentPhase;
    if (currentPhase.transition == TransitionPolicy.manual) {
      // Transition phase status to awaitingAction without advancing phase
      final updatedRun = _activeRun!.copyWith(
        phaseStatus: PhaseStatus.awaitingAction,
        stateVersion: _activeRun!.stateVersion + 1,
      );
      _activeRun = updatedRun;
      _emitState(updatedRun);
      _queue.run(() async {
        try {
          await persistencePort.persistRunAndEvents(updatedRun, []);
        } catch (_) {}
      });
      return;
    }

    _advancePhase(runId, phaseOutcome: TimerEventType.phaseFinished);
  }

  Future<bool> _advancePhase(String runId, {required TimerEventType phaseOutcome}) async {
    final run = _activeRun;
    if (run == null || run.runId != runId) return false;
    final nowUtc = wallClock.utcNow;
    final nowMono = monotonicClock.nowMs;

    final numPhases = run.routineSnapshot.phases.length;
    final nextPhaseIndex = run.currentPhaseIndex + 1;

    int newPhaseIndex = nextPhaseIndex;
    int newRepeatIndex = run.repeatIndex;
    RunStatus newStatus = RunStatus.running;

    if (nextPhaseIndex >= numPhases) {
      final repeatRule = run.routineSnapshot.repeatRule;
      if (repeatRule.mode == RepeatMode.forever || newRepeatIndex < repeatRule.count - 1) {
        newPhaseIndex = 0;
        newRepeatIndex += 1;
      } else {
        newPhaseIndex = run.currentPhaseIndex;
        newStatus = RunStatus.completed;
      }
    }

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: newStatus == RunStatus.completed ? TimerEventType.runCompleted : phaseOutcome,
      occurredAtUtc: nowUtc,
    );

    final updatedRun = run.copyWith(
      status: newStatus,
      phaseStatus: PhaseStatus.active,
      currentPhaseIndex: newPhaseIndex,
      repeatIndex: newRepeatIndex,
      accumulatedMs: 0,
      phaseStartedAtUtc: nowUtc,
      phaseStartedMonotonicMs: () => newStatus == RunStatus.running ? nowMono : null,
      pausedAtUtc: () => null,
      stateVersion: run.stateVersion + 1,
      lastEventId: () => event.eventId,
    );

    _activeRun = updatedRun;
    if (newStatus == RunStatus.running) {
      _scheduleBoundaryIfNeeded(updatedRun);
    } else {
      _boundaryTimerToken?.cancel();
    }

    _emitState(updatedRun);
    _eventController.add(event);

    try {
      await persistencePort.persistRunAndEvents(updatedRun, [event]);
      if (newStatus == RunStatus.completed) {
        await notificationPort.cancelBoundaries(runId);
      }
      return true;
    } catch (_) {
      _activeRun = run;
      return false;
    }
  }

  @override
  Future<TimerCommandResult> skipPhase(String runId) => _queue.run(() async {
    if (_activeRun == null || _activeRun!.runId != runId) {
      return TimerCommandResult(
        success: false,
        error: TimerError.runNotFound,
        stateVersion: _activeRun?.stateVersion ?? 0,
      );
    }
    if (_activeRun!.status != RunStatus.running && _activeRun!.status != RunStatus.paused) {
      return TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    final success = await _advancePhase(runId, phaseOutcome: TimerEventType.phaseSkipped);
    if (!success) {
      return TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    return TimerCommandResult(success: true, stateVersion: _activeRun!.stateVersion);
  });

  @override
  Future<TimerCommandResult> finishPhase(String runId) => _queue.run(() async {
    if (_activeRun == null || _activeRun!.runId != runId) {
      return TimerCommandResult(
        success: false,
        error: TimerError.runNotFound,
        stateVersion: _activeRun?.stateVersion ?? 0,
      );
    }
    if (_activeRun!.status != RunStatus.running && _activeRun!.status != RunStatus.paused) {
      return TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    final success = await _advancePhase(runId, phaseOutcome: TimerEventType.phaseFinished);
    if (!success) {
      return TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    return TimerCommandResult(success: true, stateVersion: _activeRun!.stateVersion);
  });

  @override
  Future<TimerCommandResult> finishRun(String runId) => _queue.run(() async {
    if (_activeRun == null || _activeRun!.runId != runId) {
      return TimerCommandResult(
        success: false,
        error: TimerError.runNotFound,
        stateVersion: _activeRun?.stateVersion ?? 0,
      );
    }
    if (_activeRun!.status == RunStatus.completed) {
      return TimerCommandResult(
        success: true,
        stateVersion: _activeRun!.stateVersion,
      );
    }
    if (_activeRun!.status != RunStatus.running && _activeRun!.status != RunStatus.paused) {
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

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runCompleted,
      occurredAtUtc: nowUtc,
    );

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.completed,
      accumulatedMs: newAccumulated,
      phaseStartedMonotonicMs: () => null,
      stateVersion: _activeRun!.stateVersion + 1,
      lastEventId: () => event.eventId,
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

  void _emitState(TimerRun run) {
    _stateController
        .add(run.calculateState(currentMonotonicMs: monotonicClock.nowMs));
  }

  @override
  Future<void> recover() async {}
}
