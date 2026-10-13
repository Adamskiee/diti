import 'package:test/test.dart';
import 'package:focus_flow_database/src/database/focus_flow_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent, PlanBlock;
import 'package:focus_flow_database/src/domain/plan_block.dart';
import 'package:focus_flow_database/src/repositories/drift_plan_block_repository.dart';

void main() {
  late FocusFlowDatabase db;
  late DriftPlanBlockRepository repository;

  setUp(() {
    db = FocusFlowDatabase.inMemory();
    repository = DriftPlanBlockRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftPlanBlockRepository', () {
    test('creates and retrieves domain PlanBlock', () async {
      final block = PlanBlock(
        id: 'block-001',
        planDate: '2026-10-13',
        scheduledStartUtc: DateTime.utc(2026, 10, 13, 10, 0),
        timezoneId: 'America/New_York',
        plannedDurationMs: 3000000,
        routineId: 'routine-study',
        status: PlanBlockStatus.scheduled,
      );

      await repository.createPlanBlock(block);

      final fetched = await repository.getBlockById('block-001');
      expect(fetched, isNotNull);
      expect(fetched!.id, equals(block.id));
      expect(fetched.planDate, equals('2026-10-13'));
      expect(fetched.timezoneId, equals('America/New_York'));
      expect(fetched.plannedDurationMs, equals(3000000));
      expect(fetched.status, equals(PlanBlockStatus.scheduled));

      final dateList = await repository.getBlocksForDate('2026-10-13');
      expect(dateList.length, equals(1));
      expect(dateList.first.id, equals('block-001'));
    });

    test('links session and marks block completed', () async {
      final block = PlanBlock(
        id: 'b-completed',
        planDate: '2026-10-13',
        scheduledStartUtc: DateTime.now().toUtc(),
        timezoneId: 'UTC',
        plannedDurationMs: 1500000,
      );
      await repository.createPlanBlock(block);

      await repository.linkSession(
        blockId: 'b-completed',
        sessionId: 'session-finish',
        actualDurationMs: 1480000,
        status: PlanBlockStatus.completed,
      );

      final updated = await repository.getBlockById('b-completed');
      expect(updated!.sessionId, equals('session-finish'));
      expect(updated.actualDurationMs, equals(1480000));
      expect(updated.status, equals(PlanBlockStatus.completed));
    });

    test('returns null when block does not exist', () async {
      final fetched = await repository.getBlockById('non-existent');
      expect(fetched, isNull);
    });

    test('updates existing domain PlanBlock', () async {
      final block = PlanBlock(
        id: 'b-update',
        planDate: '2026-10-13',
        scheduledStartUtc: DateTime.utc(2026, 10, 13, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        status: PlanBlockStatus.scheduled,
      );
      await repository.createPlanBlock(block);

      final modified = PlanBlock(
        id: 'b-update',
        planDate: '2026-10-13',
        scheduledStartUtc: DateTime.utc(2026, 10, 13, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 2400000,
        status: PlanBlockStatus.inProgress,
        actualDurationMs: 60000,
      );
      await repository.updatePlanBlock(modified);

      final fetched = await repository.getBlockById('b-update');
      expect(fetched, isNotNull);
      expect(fetched!.plannedDurationMs, equals(2400000));
      expect(fetched.status, equals(PlanBlockStatus.inProgress));
      expect(fetched.actualDurationMs, equals(60000));
    });

    test('deletes plan block', () async {
      final block = PlanBlock(
        id: 'b-to-del',
        planDate: '2026-10-13',
        scheduledStartUtc: DateTime.utc(2026, 10, 13, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
      );
      await repository.createPlanBlock(block);
      expect(await repository.getBlockById('b-to-del'), isNotNull);

      await repository.deletePlanBlock('b-to-del');
      expect(await repository.getBlockById('b-to-del'), isNull);
    });

    test('ensures timestamps are stored and retrieved normalized to UTC', () async {
      final localTime = DateTime(2026, 10, 13, 14, 30); // local time
      final block = PlanBlock(
        id: 'b-tz',
        planDate: '2026-10-13',
        scheduledStartUtc: localTime,
        timezoneId: 'America/New_York',
        plannedDurationMs: 1200000,
      );
      await repository.createPlanBlock(block);

      final fetched = await repository.getBlockById('b-tz');
      expect(fetched, isNotNull);
      expect(fetched!.scheduledStartUtc.isUtc, isTrue);
      expect(fetched.scheduledStartUtc, equals(localTime.toUtc()));
    });
  });
}
