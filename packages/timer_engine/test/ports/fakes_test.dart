import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/timer_event.dart';
import 'package:timer_engine/src/domain/timer_run.dart';
import 'package:timer_engine/src/ports/run_persistence_port.dart';
import '../fakes/in_memory_notification_port.dart';
import '../fakes/in_memory_persistence_port.dart';
import '../fakes/in_memory_routine_repository.dart';

TimerRun anyRun([String id = 'run-1']) => TimerRun(runId: id);

TimerEvent anyEvent({String eventId = 'e-1', String runId = 'run-1'}) =>
    TimerEvent(
      eventId: eventId,
      runId: runId,
      type: TimerEventType.runStarted,
      occurredAtUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
    );

void main() {
  group('In-memory Ports Test Doubles', () {
    test('InMemoryRoutineRepository saves and fetches routines', () async {
      final repo = InMemoryRoutineRepository();
      const routine = Routine(
        id: 'r1',
        name: 'Routine 1',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'P1',
            durationMs: 1000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      await repo.saveRoutine(routine);
      final fetched = await repo.getRoutine('r1');
      expect(fetched, equals(routine));
    });

    test('InMemoryRoutineRepository returns null for unknown routine id', () async {
      final repo = InMemoryRoutineRepository();
      final fetched = await repo.getRoutine('non-existent');
      expect(fetched, isNull);
    });

    test('InMemoryPersistencePort stores run and events successfully', () async {
      final port = InMemoryPersistencePort();
      final run = anyRun('run-123');
      final event1 = anyEvent(eventId: 'e-1', runId: 'run-123');
      final event2 = anyEvent(eventId: 'e-2', runId: 'run-123');

      await port.persistRunAndEvents(run, [event1, event2]);

      expect(port.activeRun, equals(run));
      expect(port.committedEvents, equals([event1, event2]));
      final latest = await port.getLatestActiveRun();
      expect(latest, equals(run));
    });

    test('InMemoryPersistencePort simulates persistence failure on write', () async {
      final port = InMemoryPersistencePort()..shouldFail = true;
      expect(
        () => port.persistRunAndEvents(anyRun(), []),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('InMemoryPersistencePort simulates persistence failure on read', () async {
      final port = InMemoryPersistencePort()..shouldFail = true;
      expect(
        () => port.getLatestActiveRun(),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('InMemoryNotificationPort records scheduled and cancelled calls', () async {
      final notif = InMemoryNotificationPort();
      await notif.scheduleBoundaryNotification(
        runId: 'run-1',
        phaseId: 'p1',
        phaseName: 'Phase 1',
        expectedUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
      );
      expect(notif.scheduledBoundaries.length, equals(1));
      expect(notif.scheduledBoundaries.first.runId, equals('run-1'));
      expect(notif.scheduledBoundaries.first.phaseId, equals('p1'));
      expect(notif.scheduledBoundaries.first.phaseName, equals('Phase 1'));
      expect(
        notif.scheduledBoundaries.first.expectedUtc,
        equals(DateTime.utc(2026, 10, 13, 10, 0, 0)),
      );

      await notif.cancelBoundaries('run-1');
      expect(notif.scheduledBoundaries.isEmpty, isTrue);
    });

    test('InMemoryNotificationPort cancelBoundaries only removes target runId', () async {
      final notif = InMemoryNotificationPort();
      await notif.scheduleBoundaryNotification(
        runId: 'run-1',
        phaseId: 'p1',
        phaseName: 'Phase 1',
        expectedUtc: DateTime.utc(2026, 10, 13, 10, 0, 0),
      );
      await notif.scheduleBoundaryNotification(
        runId: 'run-2',
        phaseId: 'p2',
        phaseName: 'Phase 2',
        expectedUtc: DateTime.utc(2026, 10, 13, 10, 5, 0),
      );
      expect(notif.scheduledBoundaries.length, equals(2));

      await notif.cancelBoundaries('run-1');
      expect(notif.scheduledBoundaries.length, equals(1));
      expect(notif.scheduledBoundaries.first.runId, equals('run-2'));
    });

    test('PersistenceException toString contains message', () {
      const defaultException = PersistenceException();
      expect(defaultException.toString(), contains('Persistence operation failed'));

      const customException = PersistenceException('Custom disk write failure');
      expect(customException.toString(), contains('Custom disk write failure'));
    });

    test('TimerEvent equality respects metadata and normalizes occurredAtUtc to UTC', () {
      final localTime = DateTime(2026, 10, 13, 10, 0, 0);
      final utcTime = localTime.toUtc();

      final e1 = TimerEvent(
        eventId: 'e-1',
        runId: 'r-1',
        type: TimerEventType.runStarted,
        occurredAtUtc: localTime,
        durationMs: 100,
        metadata: {'trigger': 'user_tap', 'count': 1},
      );

      final e2 = TimerEvent(
        eventId: 'e-1',
        runId: 'r-1',
        type: TimerEventType.runStarted,
        occurredAtUtc: utcTime,
        durationMs: 100,
        metadata: {'trigger': 'user_tap', 'count': 1},
      );

      final e3DifferentMetadata = TimerEvent(
        eventId: 'e-1',
        runId: 'r-1',
        type: TimerEventType.runStarted,
        occurredAtUtc: utcTime,
        durationMs: 100,
        metadata: {'trigger': 'auto_resume', 'count': 1},
      );

      expect(e1.occurredAtUtc.isUtc, isTrue);
      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1, isNot(equals(e3DifferentMetadata)));
    });
  });
}
