import 'dart:async';
import 'dart:math' as math;
import '../clock/cancelable_token.dart';
import '../clock/monotonic_clock.dart';
import '../clock/wall_clock.dart';
import '../domain/command_result.dart';
import '../domain/enums.dart';
import '../domain/phase_ledger_entry.dart';
import '../domain/timer_event.dart';
import '../domain/timer_run.dart';
import '../domain/timer_run_state.dart';
import '../ports/notification_port.dart';
import '../ports/routine_repository.dart';
import '../ports/run_persistence_port.dart';
import 'command_queue.dart';
import 'recovery_manager.dart';
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
  @override
  String? get activeRunId => _activeRun?.runId;

  @override
  TimerRun? getActiveRun() => _activeRun;
  TimerRun? get activeRun => _activeRun;

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
    return Duration(milliseconds: state.totalActiveElapsedMs);
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
      runStartedAtUtc: nowUtc,
      phaseFirstStartedAtUtc: nowUtc,
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
    } catch (_) {
      return TimerCommandResult(
        success: false,
        error: TimerError.persistenceFailure,
        stateVersion: _activeRun!.stateVersion,
      );
    }

    try {
      await notificationPort.cancelBoundaries(runId);
    } catch (_) {}

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
      phaseStartedAtUtc: nowUtc,
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
    final actualPhaseElapsed = _activeRun!.accumulatedMs + segmentElapsed;

    // The run ends here: the phase that was in progress becomes the last
    // ledger entry and the accumulator is emptied with it.
    final ledgerEntry = PhaseLedgerEntry(
      phaseId: _activeRun!.currentPhase.id,
      phaseName: _activeRun!.currentPhase.name,
      kind: _activeRun!.currentPhase.kind,
      phaseIndex: _activeRun!.currentPhaseIndex,
      repeatIndex: _activeRun!.repeatIndex,
      durationMs: actualPhaseElapsed,
      outcome: PhaseStatus.finished,
      startedAtUtc: _activeRun!.phaseFirstStartedAtUtc ?? nowUtc,
      endedAtUtc: nowUtc,
    );

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runCancelled,
      occurredAtUtc: nowUtc,
      durationMs: _activeRun!.ledgerTotalMs + actualPhaseElapsed,
    );

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.cancelled,
      accumulatedMs: 0,
      phaseLedger: [..._activeRun!.phaseLedger, ledgerEntry],
      phaseStartedMonotonicMs: () => null,
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

    try {
      await notificationPort.cancelBoundaries(runId);
    } catch (_) {}

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
    try {
      unawaited(notificationPort.scheduleBoundaryNotification(
        runId: run.runId,
        phaseId: phase.id,
        phaseName: phase.name,
        expectedUtc: expectedUtc,
      ).catchError((_) {}));
    } catch (_) {}

    _boundaryTimerToken = monotonicClock.schedule(
      Duration(milliseconds: remainingMs),
      () => _onBoundaryReached(run.runId, run.stateVersion),
    );
  }

  void _onBoundaryReached(String runId, int expectedVersion) {
    _queue.run(() async {
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
        try {
          await persistencePort.persistRunAndEvents(updatedRun, []);
        } catch (_) {
          return;
        }
        _activeRun = updatedRun;
        _emitState(updatedRun);
        return;
      }

      await _advancePhase(runId, phaseOutcome: TimerEventType.phaseFinished);
    });
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

    final isCompleted = newStatus == RunStatus.completed;
    final newPhaseStatus = isCompleted
        ? (phaseOutcome == TimerEventType.phaseSkipped
            ? PhaseStatus.skipped
            : PhaseStatus.finished)
        : PhaseStatus.active;

    final segmentElapsed = run.status == RunStatus.running
        ? math.max(0, nowMono - (run.phaseStartedMonotonicMs ?? nowMono))
        : 0;
    final actualPhaseElapsed = run.accumulatedMs + segmentElapsed;

    // The phase ends here: its active time moves into the ledger and the
    // accumulator starts the next phase from zero.
    final ledgerEntry = PhaseLedgerEntry(
      phaseId: run.currentPhase.id,
      phaseName: run.currentPhase.name,
      kind: run.currentPhase.kind,
      phaseIndex: run.currentPhaseIndex,
      repeatIndex: run.repeatIndex,
      durationMs: actualPhaseElapsed,
      outcome: phaseOutcome == TimerEventType.phaseSkipped
          ? PhaseStatus.skipped
          : PhaseStatus.finished,
      startedAtUtc: run.phaseFirstStartedAtUtc ?? nowUtc,
      endedAtUtc: nowUtc,
    );
    const newAccumulatedMs = 0;

    final List<TimerEvent> events;
    final String lastEventId;

    if (isCompleted) {
      final phaseEvent = TimerEvent(
        eventId: 'evt-phase-${nowUtc.millisecondsSinceEpoch}',
        runId: runId,
        type: phaseOutcome,
        occurredAtUtc: nowUtc,
        durationMs: actualPhaseElapsed,
      );
      final runCompletedEvent = TimerEvent(
        eventId: 'evt-run-${nowUtc.millisecondsSinceEpoch}',
        runId: runId,
        type: TimerEventType.runCompleted,
        occurredAtUtc: nowUtc,
        durationMs: run.ledgerTotalMs + actualPhaseElapsed,
      );
      events = [phaseEvent, runCompletedEvent];
      lastEventId = runCompletedEvent.eventId;
    } else {
      final phaseEvent = TimerEvent(
        eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
        runId: runId,
        type: phaseOutcome,
        occurredAtUtc: nowUtc,
        durationMs: actualPhaseElapsed,
      );
      events = [phaseEvent];
      lastEventId = phaseEvent.eventId;
    }

    final updatedRun = run.copyWith(
      status: newStatus,
      phaseStatus: newPhaseStatus,
      currentPhaseIndex: newPhaseIndex,
      repeatIndex: newRepeatIndex,
      accumulatedMs: newAccumulatedMs,
      phaseLedger: [...run.phaseLedger, ledgerEntry],
      phaseFirstStartedAtUtc: nowUtc,
      phaseStartedAtUtc: nowUtc,
      phaseStartedMonotonicMs: () => newStatus == RunStatus.running ? nowMono : null,
      pausedAtUtc: () => null,
      stateVersion: run.stateVersion + 1,
      lastEventId: () => lastEventId,
    );

    try {
      await persistencePort.persistRunAndEvents(updatedRun, events);
    } catch (_) {
      return false;
    }

    if (isCompleted) {
      try {
        await notificationPort.cancelBoundaries(runId);
      } catch (_) {}
    }

    _activeRun = updatedRun;
    if (newStatus == RunStatus.running) {
      _scheduleBoundaryIfNeeded(updatedRun);
    } else {
      _boundaryTimerToken?.cancel();
    }

    _emitState(updatedRun);
    for (final event in events) {
      _eventController.add(event);
    }
    return true;
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
    final actualPhaseElapsed = _activeRun!.accumulatedMs + segmentElapsed;

    // The run ends here: the phase that was in progress becomes the last
    // ledger entry and the accumulator is emptied with it.
    final ledgerEntry = PhaseLedgerEntry(
      phaseId: _activeRun!.currentPhase.id,
      phaseName: _activeRun!.currentPhase.name,
      kind: _activeRun!.currentPhase.kind,
      phaseIndex: _activeRun!.currentPhaseIndex,
      repeatIndex: _activeRun!.repeatIndex,
      durationMs: actualPhaseElapsed,
      outcome: PhaseStatus.finished,
      startedAtUtc: _activeRun!.phaseFirstStartedAtUtc ?? nowUtc,
      endedAtUtc: nowUtc,
    );

    final event = TimerEvent(
      eventId: 'evt-${nowUtc.millisecondsSinceEpoch}',
      runId: runId,
      type: TimerEventType.runCompleted,
      occurredAtUtc: nowUtc,
      durationMs: _activeRun!.ledgerTotalMs + actualPhaseElapsed,
    );

    final updatedRun = _activeRun!.copyWith(
      status: RunStatus.completed,
      phaseStatus: PhaseStatus.finished,
      accumulatedMs: 0,
      phaseLedger: [..._activeRun!.phaseLedger, ledgerEntry],
      phaseStartedMonotonicMs: () => null,
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

    try {
      await notificationPort.cancelBoundaries(runId);
    } catch (_) {}

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
  Future<void> recover() => _queue.run(() async {
    final activeRun = await persistencePort.getLatestActiveRun();
    if (activeRun == null) return;
    if (activeRun.status == RunStatus.completed ||
        activeRun.status == RunStatus.cancelled) {
      _activeRun = activeRun;
      return;
    }

    final recoveryManager = RecoveryManager(wallClock: wallClock);
    final reconciled =
        recoveryManager.reconcile(activeRun, monotonicClock.nowMs);

    if (reconciled.events.isNotEmpty || reconciled.run != activeRun) {
      await persistencePort.persistRunAndEvents(reconciled.run, reconciled.events);
    }

    _activeRun = reconciled.run;
    if (_activeRun!.status == RunStatus.running) {
      _scheduleBoundaryIfNeeded(_activeRun!);
    } else {
      _boundaryTimerToken?.cancel();
      if (_activeRun!.status == RunStatus.completed ||
          _activeRun!.status == RunStatus.cancelled) {
        await notificationPort.cancelBoundaries(_activeRun!.runId);
      }
    }
    _emitState(_activeRun!);
    for (final event in reconciled.events) {
      _eventController.add(event);
    }
  });

  @override
  void cancelBoundaryTimer() {
    _boundaryTimerToken?.cancel();
    _boundaryTimerToken = null;
  }

  @override
  void dispose() {
    _boundaryTimerToken?.cancel();
    _stateController.close();
    _eventController.close();
  }
}
