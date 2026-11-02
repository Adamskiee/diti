import 'package:test/test.dart';
import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/daos/timer_runs_dao.dart';

void main() {
  late DitiDatabase db;
  late TimerRunsDao dao;

  setUp(() {
    db = DitiDatabase.inMemory();
    dao = TimerRunsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TimerRunsDao', () {
    test(
        'upserts run and retrieves latest active run ordered by started timestamp',
        () async {
      final t1 = DateTime.utc(2026, 10, 13, 10, 0);
      final t2 = DateTime.utc(2026, 10, 13, 11, 0);

      await dao.upsertRun(
        TimerRunsCompanion.insert(
          runId: 'run-1',
          status: 'running',
          phaseStatus: 'active',
          currentPhaseIndex: 0,
          repeatIndex: 0,
          accumulatedMs: 0,
          phaseStartedAtUtc: t1,
          stateVersion: 1,
          routineSnapshotJson: '{}',
        ),
      );

      await dao.upsertRun(
        TimerRunsCompanion.insert(
          runId: 'run-2',
          status: 'running',
          phaseStatus: 'active',
          currentPhaseIndex: 0,
          repeatIndex: 0,
          accumulatedMs: 0,
          phaseStartedAtUtc: t2,
          stateVersion: 1,
          routineSnapshotJson: '{}',
        ),
      );

      final latest = await dao.getLatestActiveRun();
      expect(latest, isNotNull);
      expect(latest!.runId, equals('run-2'));
    });

    test('ignores completed and cancelled runs when querying active run',
        () async {
      await dao.upsertRun(
        TimerRunsCompanion.insert(
          runId: 'run-completed',
          status: 'completed',
          phaseStatus: 'finished',
          currentPhaseIndex: 0,
          repeatIndex: 0,
          accumulatedMs: 5000,
          phaseStartedAtUtc: DateTime.now().toUtc(),
          stateVersion: 5,
          routineSnapshotJson: '{}',
        ),
      );

      final active = await dao.getLatestActiveRun();
      expect(active, isNull);
    });

    test('batch inserts journal events and ignores duplicate event IDs',
        () async {
      final now = DateTime.now().toUtc();
      await dao.upsertRun(
        TimerRunsCompanion.insert(
          runId: 'run-ev',
          status: 'running',
          phaseStatus: 'active',
          currentPhaseIndex: 0,
          repeatIndex: 0,
          accumulatedMs: 0,
          phaseStartedAtUtc: now,
          stateVersion: 1,
          routineSnapshotJson: '{}',
        ),
      );

      final events = [
        TimerEventsCompanion.insert(
          eventId: 'e-1',
          runId: 'run-ev',
          eventType: 'runStarted',
          occurredAtUtc: now,
        ),
        TimerEventsCompanion.insert(
          eventId: 'e-2',
          runId: 'run-ev',
          eventType: 'runPaused',
          occurredAtUtc: now.add(const Duration(seconds: 10)),
        ),
      ];

      await dao.insertEvents(events);

      // Re-inserting e-1 with mode insertOrIgnore must not throw
      await dao.insertEvents([
        TimerEventsCompanion.insert(
          eventId: 'e-1',
          runId: 'run-ev',
          eventType: 'runStarted',
          occurredAtUtc: now,
        ),
      ]);

      final retrieved = await dao.getEventsForRun('run-ev');
      expect(retrieved.length, equals(2));
      expect(retrieved[0].eventId, equals('e-1'));
      expect(retrieved[1].eventId, equals('e-2'));
    });

    test('deletes run and cascades event deletion', () async {
      final now = DateTime.now().toUtc();
      await dao.upsertRun(
        TimerRunsCompanion.insert(
          runId: 'run-to-delete',
          status: 'running',
          phaseStatus: 'active',
          currentPhaseIndex: 0,
          repeatIndex: 0,
          accumulatedMs: 0,
          phaseStartedAtUtc: now,
          stateVersion: 1,
          routineSnapshotJson: '{}',
        ),
      );

      await dao.insertEvents([
        TimerEventsCompanion.insert(
          eventId: 'e-del-1',
          runId: 'run-to-delete',
          eventType: 'runStarted',
          occurredAtUtc: now,
        ),
      ]);

      final deletedCount = await dao.deleteRun('run-to-delete');
      expect(deletedCount, equals(1));

      final active = await dao.getLatestActiveRun();
      expect(active, isNull);

      final events = await dao.getEventsForRun('run-to-delete');
      expect(events, isEmpty);
    });
  });
}
