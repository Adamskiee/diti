import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/src/database/diti_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent;
import 'package:diti_database/src/domain/session_record.dart';
import 'package:diti_database/src/domain/session_app_usage_record.dart';
import 'package:diti_database/src/domain/session_validator.dart';
import 'package:diti_database/src/repositories/drift_session_repository.dart';

void main() {
  late DitiDatabase db;
  late DriftSessionRepository repository;

  setUp(() {
    db = DitiDatabase.inMemory();
    repository = DriftSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftSessionRepository', () {
    const routine = Routine(
      id: 'r-sess',
      name: 'Work Block',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [
        RoutinePhase(id: 'p1', name: 'Focus', durationMs: 60000, transition: TransitionPolicy.auto),
      ],
    );

    test('records and retrieves session record with snapshot and events', () async {
      final session = SessionRecord(
        sessionId: 'session-123',
        routineId: 'r-sess',
        planBlockId: 'block-abc',
        routineName: 'Work Block',
        startedAtUtc: DateTime.utc(2026, 10, 13, 14, 0),
        endedAtUtc: DateTime.utc(2026, 10, 13, 14, 25),
        totalDurationMs: 1500000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
        events: [
          SessionEventRecord(
            eventId: 'ev-s1',
            sessionId: 'session-123',
            eventType: 'phaseFinished',
            occurredAtUtc: DateTime.utc(2026, 10, 13, 14, 25),
            phaseId: 'p1',
            phaseName: 'Focus',
            durationMs: 1500000,
            outcome: 'completed',
          ),
        ],
      );

      await repository.recordSession(session);

      final fetched = await repository.getSession('session-123');
      expect(fetched, isNotNull);
      expect(fetched!.sessionId, equals(session.sessionId));
      expect(fetched.routineId, equals('r-sess'));
      expect(fetched.planBlockId, equals('block-abc'));
      expect(fetched.routineName, equals('Work Block'));
      expect(fetched.totalDurationMs, equals(1500000));
      expect(fetched.outcome, equals(SessionOutcome.completed));
      expect(fetched.routineSnapshot, equals(routine));
      expect(fetched.events.length, equals(1));
      expect(fetched.events.first.eventId, equals('ev-s1'));
      expect(fetched.events.first.phaseName, equals('Focus'));
      expect(fetched.events.first.durationMs, equals(1500000));
      expect(fetched.events.first.outcome, equals('completed'));

      final forBlock = await repository.getSessionsForPlanBlock('block-abc');
      expect(forBlock.length, equals(1));
      expect(forBlock.first.sessionId, equals('session-123'));
    });

    test('session events round-trip their kind', () async {
      final session = SessionRecord(
        sessionId: 'session-kinds',
        routineId: 'r-sess',
        routineName: 'Work Block',
        startedAtUtc: DateTime.utc(2026, 10, 13, 9, 0),
        endedAtUtc: DateTime.utc(2026, 10, 13, 9, 30),
        totalDurationMs: 1800000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
        events: [
          SessionEventRecord(
            eventId: 'ev-kind-focus',
            sessionId: 'session-kinds',
            eventType: 'phaseFinished',
            occurredAtUtc: DateTime.utc(2026, 10, 13, 9, 25),
            phaseId: 'p1',
            phaseName: 'Focus',
            durationMs: 1500000,
            outcome: 'completed',
            kind: PhaseKind.focus,
          ),
          SessionEventRecord(
            eventId: 'ev-kind-rest',
            sessionId: 'session-kinds',
            eventType: 'phaseFinished',
            occurredAtUtc: DateTime.utc(2026, 10, 13, 9, 30),
            phaseId: 'p2',
            phaseName: 'Short Break',
            durationMs: 300000,
            outcome: 'completed',
            kind: PhaseKind.rest,
          ),
        ],
      );

      await repository.recordSession(session);

      final fetched = await repository.getSession('session-kinds');
      expect(fetched, isNotNull);
      expect(fetched!.events.length, equals(2));
      expect(fetched.events[0].kind, equals(PhaseKind.focus));
      expect(fetched.events[1].kind, equals(PhaseKind.rest));
    });

    test('session app usages round-trip properly', () async {
      final session = SessionRecord(
        sessionId: 'session-usages',
        routineId: 'r-sess',
        routineName: 'Work Block',
        startedAtUtc: DateTime.utc(2026, 10, 13, 9, 0),
        endedAtUtc: DateTime.utc(2026, 10, 13, 9, 30),
        totalDurationMs: 1800000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
        appUsages: const [
          SessionAppUsageRecord(
            id: 'u1',
            sessionId: 'session-usages',
            appName: 'Visual Studio Code',
            category: 'IDE',
            sampleTitle: 'main.dart',
            durationMs: 1200000,
          ),
          SessionAppUsageRecord(
            id: 'u2',
            sessionId: 'session-usages',
            appName: 'Chrome',
            category: 'Documentation',
            sampleTitle: 'Flutter Docs',
            durationMs: 600000,
          ),
        ],
      );

      await repository.recordSession(session);

      final fetched = await repository.getSession('session-usages');
      expect(fetched, isNotNull);
      expect(fetched!.appUsages.length, equals(2));
      expect(fetched.appUsages[0].id, equals('u1'));
      expect(fetched.appUsages[0].appName, equals('Visual Studio Code'));
      expect(fetched.appUsages[0].category, equals('IDE'));
      expect(fetched.appUsages[0].sampleTitle, equals('main.dart'));
      expect(fetched.appUsages[0].durationMs, equals(1200000));
      expect(fetched.appUsages[1].id, equals('u2'));
      expect(fetched.appUsages[1].appName, equals('Chrome'));
      expect(fetched.appUsages[1].category, equals('Documentation'));
    });

    test('returns null for non-existent session', () async {
      final fetched = await repository.getSession('non-existent');
      expect(fetched, isNull);
    });

    test('recordSession throws SessionValidationException when session is invalid', () async {
      final invalidSession = SessionRecord(
        sessionId: 'inv-1',
        routineId: 'r1',
        routineName: 'Test Routine',
        startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
        endedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
        totalDurationMs: 0, // Invalid: < 1000ms
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
      );

      expect(
        () => repository.recordSession(invalidSession),
        throwsA(isA<SessionValidationException>()),
      );
    });

    test('recordSession upserts existing sessionId without duplicating or failing', () async {
      final sessionInitial = SessionRecord(
        sessionId: 'session-idempotent',
        routineId: 'r1',
        routineName: 'Initial Name',
        startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
        endedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
        totalDurationMs: 1500000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
      );
      await repository.recordSession(sessionInitial);

      final sessionUpdated = SessionRecord(
        sessionId: 'session-idempotent',
        routineId: 'r1',
        routineName: 'Updated Name',
        startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
        endedAtUtc: DateTime.utc(2026, 10, 20, 10, 30),
        totalDurationMs: 1800000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
      );
      await repository.recordSession(sessionUpdated);

      final retrieved = await repository.getSession('session-idempotent');
      expect(retrieved, isNotNull);
      expect(retrieved!.routineName, equals('Updated Name'));
      expect(retrieved.totalDurationMs, equals(1800000));
    });

    test('retrieves sessions in UTC range ordered descending by started timestamp', () async {
      final session1 = SessionRecord(
        sessionId: 's-early',
        routineName: 'Early',
        startedAtUtc: DateTime.utc(2026, 10, 13, 8, 0),
        endedAtUtc: DateTime.utc(2026, 10, 13, 8, 30),
        totalDurationMs: 1800000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
      );

      final session2 = SessionRecord(
        sessionId: 's-late',
        routineName: 'Late',
        startedAtUtc: DateTime.utc(2026, 10, 13, 10, 0),
        endedAtUtc: DateTime.utc(2026, 10, 13, 10, 30),
        totalDurationMs: 1800000,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
      );

      await repository.recordSession(session1);
      await repository.recordSession(session2);

      final inRange = await repository.getSessionsInRange(
        DateTime.utc(2026, 10, 13, 7, 0),
        DateTime.utc(2026, 10, 13, 11, 0),
      );
      expect(inRange.length, equals(2));
      expect(inRange[0].sessionId, equals('s-late'));
      expect(inRange[1].sessionId, equals('s-early'));

      final narrow = await repository.getSessionsInRange(
        DateTime.utc(2026, 10, 13, 9, 30),
        DateTime.utc(2026, 10, 13, 10, 30),
      );
      expect(narrow.length, equals(1));
      expect(narrow.first.sessionId, equals('s-late'));
    });

    test('deletes session and cascades event deletion', () async {
      final session = SessionRecord(
        sessionId: 's-to-delete',
        routineName: 'Delete Me',
        startedAtUtc: DateTime.utc(2026, 10, 13, 12, 0),
        endedAtUtc: DateTime.utc(2026, 10, 13, 12, 15),
        totalDurationMs: 900000,
        outcome: SessionOutcome.cancelled,
        routineSnapshot: routine,
        events: [
          SessionEventRecord(
            eventId: 'ev-del',
            sessionId: 's-to-delete',
            eventType: 'runCancelled',
            occurredAtUtc: DateTime.utc(2026, 10, 13, 12, 15),
          ),
        ],
      );

      await repository.recordSession(session);
      expect(await repository.getSession('s-to-delete'), isNotNull);

      await repository.deleteSession('s-to-delete');
      expect(await repository.getSession('s-to-delete'), isNull);
    });
  });
}
