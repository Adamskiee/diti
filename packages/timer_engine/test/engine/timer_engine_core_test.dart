import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/timer_event.dart';
import 'package:timer_engine/src/domain/timer_run_state.dart';
import 'package:timer_engine/src/engine/timer_engine_impl.dart';
import '../fakes/fake_clock.dart';
import '../fakes/in_memory_notification_port.dart';
import '../fakes/in_memory_persistence_port.dart';
import '../fakes/in_memory_routine_repository.dart';

void main() {
  late FakeClock clock;
  late InMemoryRoutineRepository routineRepo;
  late InMemoryPersistencePort persistence;
  late InMemoryNotificationPort notifications;
  late TimerEngineImpl engine;

  final validRoutine = Routine(
    id: 'study-routine',
    name: 'Study Routine',
    repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
    phases: const [
      RoutinePhase(
        id: 'p1',
        name: 'Study',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
      ),
    ],
  );

  setUp(() async {
    clock = FakeClock();
    routineRepo = InMemoryRoutineRepository();
    persistence = InMemoryPersistencePort();
    notifications = InMemoryNotificationPort();
    await routineRepo.saveRoutine(validRoutine);

    engine = TimerEngineImpl(
      monotonicClock: clock,
      wallClock: clock,
      routineRepository: routineRepo,
      persistencePort: persistence,
      notificationPort: notifications,
    );
  });

  group('Core TimerEngine Operations', () {
    test('T-001: Start a valid routine starts first phase and sets status to running', () async {
      final result = await engine.start('study-routine');
      expect(result.success, isTrue);
      expect(result.error, isNull);

      final state = engine.getState(engine.activeRunId!);
      expect(state!.status, equals(RunStatus.running));
      expect(state.currentPhase.id, equals('p1'));
    });

    test('getActiveRun returns null initially and returns active TimerRun after start', () async {
      expect(engine.getActiveRun(), isNull);
      await engine.start('study-routine');
      final activeRun = engine.getActiveRun();
      expect(activeRun, isNotNull);
      expect(activeRun!.runId, equals(engine.activeRunId));
      expect(activeRun.status, equals(RunStatus.running));
    });

    test('T-002: Start a routine with no phases rejects with invalidConfiguration', () async {
      const emptyRoutine = Routine(
        id: 'empty',
        name: 'Empty',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [],
      );
      await routineRepo.saveRoutine(emptyRoutine);

      final result = await engine.start('empty');
      expect(result.success, isFalse);
      expect(result.error, equals(TimerError.invalidConfiguration));
    });

    test('T-003 & T-004: Paused time is excluded from elapsed time', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 10));
      final pauseResult = await engine.pause(runId);
      expect(pauseResult.success, isTrue);

      clock.advance(const Duration(minutes: 5));
      final pausedElapsed = await engine.elapsed(runId);
      expect(pausedElapsed, equals(const Duration(minutes: 10)));

      final resumeResult = await engine.resume(runId);
      expect(resumeResult.success, isTrue);

      clock.advance(const Duration(minutes: 3));
      final resumedElapsed = await engine.elapsed(runId);
      expect(resumedElapsed, equals(const Duration(minutes: 13)));
    });

    test('T-005: Pause an already paused run is an idempotent no-op without duplicating time', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;

      clock.advance(const Duration(minutes: 5));
      await engine.pause(runId);

      // Call pause a second time
      final secondPause = await engine.pause(runId);
      expect(secondPause.success, isTrue);

      final elapsed = await engine.elapsed(runId);
      expect(elapsed, equals(const Duration(minutes: 5)));
    });

    test('T-013: Invalid state transition returns typed error without mutating state', () async {
      final result = await engine.resume('non-existent-run');
      expect(result.success, isFalse);
      expect(result.error, equals(TimerError.runNotFound));
    });

    test('T-014: Routine edited after run starts does not affect active run snapshot', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;

      // Mutate repository routine
      const updatedRoutine = Routine(
        id: 'study-routine',
        name: 'Renamed Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 5),
        phases: [
          RoutinePhase(
            id: 'different',
            name: 'Different',
            durationMs: 99999,
            transition: TransitionPolicy.manual,
          ),
        ],
      );
      await routineRepo.saveRoutine(updatedRoutine);

      final state = engine.getState(runId);
      expect(state!.currentPhase.id, equals('p1'));
      expect(state.currentPhase.name, equals('Study'));
    });

    test('T-016: Persistence failure surfaces error and rolls back in-memory mutation', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;

      persistence.shouldFail = true;
      final pauseResult = await engine.pause(runId);

      expect(pauseResult.success, isFalse);
      expect(pauseResult.error, equals(TimerError.persistenceFailure));

      // Engine remains running
      final state = engine.getState(runId);
      expect(state!.status, equals(RunStatus.running));
    });

    test('Stop transitions run to cancelled, cancels boundaries, and emits cancelled event', () async {
      final emittedStates = <TimerRunState>[];
      final emittedEvents = <TimerEvent>[];
      final stateSub = engine.stateStream.listen(emittedStates.add);
      final eventSub = engine.eventStream.listen(emittedEvents.add);

      await engine.start('study-routine');
      final runId = engine.activeRunId!;
      expect(notifications.scheduledBoundaries, hasLength(1));

      final stopResult = await engine.stop(runId);
      expect(stopResult.success, isTrue);

      final state = engine.getState(runId);
      expect(state!.status, equals(RunStatus.cancelled));
      expect(notifications.scheduledBoundaries, isEmpty);

      // Verify event emission
      expect(emittedEvents.any((e) => e.type == TimerEventType.runCancelled), isTrue);

      await stateSub.cancel();
      await eventSub.cancel();
    });

    test('Stop on non-existent run returns runNotFound error', () async {
      final result = await engine.stop('missing-run');
      expect(result.success, isFalse);
      expect(result.error, equals(TimerError.runNotFound));
    });

    test('Resume on currently running run returns invalidTransition', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;

      final resumeResult = await engine.resume(runId);
      expect(resumeResult.success, isFalse);
      expect(resumeResult.error, equals(TimerError.invalidTransition));
    });

    test('Pause on stopped run returns invalidTransition', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;
      await engine.stop(runId);

      final pauseResult = await engine.pause(runId);
      expect(pauseResult.success, isFalse);
      expect(pauseResult.error, equals(TimerError.invalidTransition));
    });

    test('Calling start() while run is running returns invalidTransition', () async {
      final start1 = await engine.start('study-routine');
      expect(start1.success, isTrue);

      final start2 = await engine.start('study-routine');
      expect(start2.success, isFalse);
      expect(start2.error, equals(TimerError.invalidTransition));
    });

    test('Calling start() while run is paused returns invalidTransition', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;
      await engine.pause(runId);

      final start2 = await engine.start('study-routine');
      expect(start2.success, isFalse);
      expect(start2.error, equals(TimerError.invalidTransition));
    });

    test('pause() cancels boundary notifications', () async {
      await engine.start('study-routine');
      final runId = engine.activeRunId!;
      expect(notifications.scheduledBoundaries, hasLength(1));

      final pauseResult = await engine.pause(runId);
      expect(pauseResult.success, isTrue);
      expect(notifications.scheduledBoundaries, isEmpty);

      // And resume reschedules it
      final resumeResult = await engine.resume(runId);
      expect(resumeResult.success, isTrue);
      expect(notifications.scheduledBoundaries, hasLength(1));
    });

    test('lastEventId is updated on TimerRun after start, pause, resume, and stop', () async {
      final events = <TimerEvent>[];
      final eventSub = engine.eventStream.listen(events.add);

      await engine.start('study-routine');
      final runId = engine.activeRunId!;
      expect(persistence.activeRun?.lastEventId, isNotNull);
      expect(persistence.activeRun?.lastEventId, equals(events.last.eventId));

      await engine.pause(runId);
      expect(persistence.activeRun?.lastEventId, equals(events.last.eventId));

      await engine.resume(runId);
      expect(persistence.activeRun?.lastEventId, equals(events.last.eventId));

      await engine.stop(runId);
      expect(persistence.activeRun?.lastEventId, equals(events.last.eventId));

      await eventSub.cancel();
    });
  });
}
