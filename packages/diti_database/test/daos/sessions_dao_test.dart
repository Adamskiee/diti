import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';
import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/daos/sessions_dao.dart';

void main() {
  late DitiDatabase db;
  late SessionsDao dao;

  setUp(() {
    db = DitiDatabase.inMemory();
    dao = SessionsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionsDao', () {
    test('creates session with events atomically and retrieves by ID and range',
        () async {
      final start = DateTime.utc(2026, 10, 13, 9, 0);
      final end = DateTime.utc(2026, 10, 13, 9, 30);

      await dao.createSessionWithEvents(
        SessionsCompanion.insert(
          sessionId: 's-1',
          routineName: 'Morning Routine',
          startedAtUtc: start,
          endedAtUtc: end,
          totalDurationMs: 1800000,
          outcome: 'completed',
          routineSnapshotJson: '{}',
        ),
        [
          SessionEventsCompanion.insert(
            eventId: 'se-1',
            sessionId: 's-1',
            eventType: 'phaseFinished',
            occurredAtUtc: end,
            durationMs: const Value(1800000),
          ),
        ],
      );

      final session = await dao.getSessionById('s-1');
      expect(session, isNotNull);
      expect(session!.routineName, equals('Morning Routine'));

      final events = await dao.getEventsForSession('s-1');
      expect(events.length, equals(1));
      expect(events.first.eventId, equals('se-1'));

      final rangeSessions = await dao.getSessionsInRange(
        startUtc: DateTime.utc(2026, 10, 13, 8, 0),
        endUtc: DateTime.utc(2026, 10, 13, 10, 0),
      );
      expect(rangeSessions.length, equals(1));
    });

    test('retrieves sessions for plan block', () async {
      final now = DateTime.now().toUtc();
      await dao.createSessionWithEvents(
        SessionsCompanion.insert(
          sessionId: 's-block',
          planBlockId: const Value('block-123'),
          routineName: 'Block Routine',
          startedAtUtc: now,
          endedAtUtc: now,
          totalDurationMs: 500,
          outcome: 'completed',
          routineSnapshotJson: '{}',
        ),
        [],
      );

      final blockSessions = await dao.getSessionsForPlanBlock('block-123');
      expect(blockSessions.length, equals(1));
      expect(blockSessions.first.sessionId, equals('s-block'));

      final otherBlockSessions =
          await dao.getSessionsForPlanBlock('other-block');
      expect(otherBlockSessions, isEmpty);
    });

    test('deletes session and cascades event deletion', () async {
      final now = DateTime.now().toUtc();
      await dao.createSessionWithEvents(
        SessionsCompanion.insert(
          sessionId: 's-delete',
          routineName: 'R',
          startedAtUtc: now,
          endedAtUtc: now,
          totalDurationMs: 100,
          outcome: 'cancelled',
          routineSnapshotJson: '{}',
        ),
        [
          SessionEventsCompanion.insert(
            eventId: 'se-del',
            sessionId: 's-delete',
            eventType: 'runCancelled',
            occurredAtUtc: now,
          ),
        ],
      );

      await dao.deleteSession('s-delete');

      final session = await dao.getSessionById('s-delete');
      expect(session, isNull);

      final events = await dao.getEventsForSession('s-delete');
      expect(events, isEmpty);
    });
  });
}
