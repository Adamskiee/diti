import 'package:test/test.dart';
import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/daos/plan_blocks_dao.dart';

void main() {
  late DitiDatabase db;
  late PlanBlocksDao dao;

  setUp(() {
    db = DitiDatabase.inMemory();
    dao = PlanBlocksDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlanBlocksDao', () {
    test('inserts and retrieves plan blocks ordered by scheduled start time',
        () async {
      final t1 = DateTime.utc(2026, 10, 13, 9, 0);
      final t2 = DateTime.utc(2026, 10, 13, 14, 0);

      await dao.insertPlanBlock(
        PlanBlocksCompanion.insert(
          id: 'b-2',
          planDate: '2026-10-13',
          scheduledStartUtc: t2,
          timezoneId: 'UTC',
          plannedDurationMs: 1800000,
          status: 'scheduled',
        ),
      );

      await dao.insertPlanBlock(
        PlanBlocksCompanion.insert(
          id: 'b-1',
          planDate: '2026-10-13',
          scheduledStartUtc: t1,
          timezoneId: 'UTC',
          plannedDurationMs: 3600000,
          status: 'scheduled',
        ),
      );

      final blocks = await dao.getPlanBlocksForDate('2026-10-13');
      expect(blocks.length, equals(2));
      expect(blocks[0].id, equals('b-1'));
      expect(blocks[1].id, equals('b-2'));

      final adjacentBlocks = await dao.getPlanBlocksForDate('2026-10-14');
      expect(adjacentBlocks, isEmpty);
    });

    test('links session and updates actual duration', () async {
      await dao.insertPlanBlock(
        PlanBlocksCompanion.insert(
          id: 'b-link',
          planDate: '2026-10-13',
          scheduledStartUtc: DateTime.now().toUtc(),
          timezoneId: 'UTC',
          plannedDurationMs: 10000,
          status: 'scheduled',
        ),
      );

      await dao.linkSession(
        blockId: 'b-link',
        sessionId: 'sess-xyz',
        actualDurationMs: 9500,
        status: 'completed',
      );

      final updated = await dao.getPlanBlockById('b-link');
      expect(updated, isNotNull);
      expect(updated!.sessionId, equals('sess-xyz'));
      expect(updated.actualDurationMs, equals(9500));
      expect(updated.status, equals('completed'));
    });

    test('updates existing plan block', () async {
      final t = DateTime.utc(2026, 10, 13, 9, 0);
      await dao.insertPlanBlock(
        PlanBlocksCompanion.insert(
          id: 'b-upd',
          planDate: '2026-10-13',
          scheduledStartUtc: t,
          timezoneId: 'UTC',
          plannedDurationMs: 1800000,
          status: 'scheduled',
        ),
      );

      final success = await dao.updatePlanBlock(
        PlanBlocksCompanion.insert(
          id: 'b-upd',
          planDate: '2026-10-13',
          scheduledStartUtc: t,
          timezoneId: 'UTC',
          plannedDurationMs: 2400000,
          status: 'inProgress',
        ),
      );

      expect(success, isTrue);
      final updated = await dao.getPlanBlockById('b-upd');
      expect(updated, isNotNull);
      expect(updated!.plannedDurationMs, equals(2400000));
      expect(updated.status, equals('inProgress'));
    });

    test('deletes plan block by id', () async {
      await dao.insertPlanBlock(
        PlanBlocksCompanion.insert(
          id: 'b-del',
          planDate: '2026-10-13',
          scheduledStartUtc: DateTime.utc(2026, 10, 13, 9, 0),
          timezoneId: 'UTC',
          plannedDurationMs: 1800000,
          status: 'scheduled',
        ),
      );

      final count = await dao.deletePlanBlock('b-del');
      expect(count, equals(1));
      final fetched = await dao.getPlanBlockById('b-del');
      expect(fetched, isNull);
    });
  });
}
