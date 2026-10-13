import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';
import 'package:focus_flow_database/src/database/focus_flow_database.dart';
import 'package:focus_flow_database/src/daos/routines_dao.dart';

void main() {
  late FocusFlowDatabase db;
  late RoutinesDao dao;

  setUp(() {
    db = FocusFlowDatabase.inMemory();
    dao = RoutinesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RoutinesDao', () {
    test('upserts routine with phases atomically and preserves phase ordering', () async {
      final now = DateTime.now().toUtc();
      await dao.upsertRoutineWithPhases(
        RoutinesCompanion.insert(
          id: 'routine-1',
          name: 'Pomodoro',
          repeatMode: 'count',
          repeatCount: const Value(4),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
        [
          RoutinePhasesCompanion.insert(
            id: 'p-focus',
            routineId: 'routine-1',
            orderIndex: 0,
            name: 'Focus',
            durationMs: const Value(1500000),
            transitionPolicy: 'auto',
          ),
          RoutinePhasesCompanion.insert(
            id: 'p-break',
            routineId: 'routine-1',
            orderIndex: 1,
            name: 'Break',
            durationMs: const Value(300000),
            transitionPolicy: 'manual',
          ),
        ],
      );

      final routine = await dao.getRoutineById('routine-1');
      expect(routine, isNotNull);
      expect(routine!.name, equals('Pomodoro'));

      final phases = await dao.getPhasesForRoutine('routine-1');
      expect(phases.length, equals(2));
      expect(phases[0].id, equals('p-focus'));
      expect(phases[0].orderIndex, equals(0));
      expect(phases[1].id, equals('p-break'));
      expect(phases[1].orderIndex, equals(1));
    });

    test('updates existing routine and replaces phases on subsequent upsert', () async {
      final now = DateTime.now().toUtc();
      await dao.upsertRoutineWithPhases(
        RoutinesCompanion.insert(
          id: 'routine-1',
          name: 'Pomodoro',
          repeatMode: 'count',
          repeatCount: const Value(4),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
        [
          RoutinePhasesCompanion.insert(
            id: 'p-focus',
            routineId: 'routine-1',
            orderIndex: 0,
            name: 'Focus',
            durationMs: const Value(1500000),
            transitionPolicy: 'auto',
          ),
        ],
      );

      final later = now.add(const Duration(minutes: 5));
      await dao.upsertRoutineWithPhases(
        RoutinesCompanion.insert(
          id: 'routine-1',
          name: 'Pomodoro Updated',
          repeatMode: 'forever',
          createdAtUtc: now,
          updatedAtUtc: later,
        ),
        [
          RoutinePhasesCompanion.insert(
            id: 'p-new-focus',
            routineId: 'routine-1',
            orderIndex: 0,
            name: 'New Focus',
            durationMs: const Value(1800000),
            transitionPolicy: 'manual',
          ),
        ],
      );

      final routine = await dao.getRoutineById('routine-1');
      expect(routine, isNotNull);
      expect(routine!.name, equals('Pomodoro Updated'));
      expect(routine.repeatMode, equals('forever'));

      final phases = await dao.getPhasesForRoutine('routine-1');
      expect(phases.length, equals(1));
      expect(phases[0].id, equals('p-new-focus'));
    });

    test('deletes routine and cascades phase deletion', () async {
      final now = DateTime.now().toUtc();
      await dao.upsertRoutineWithPhases(
        RoutinesCompanion.insert(
          id: 'routine-to-delete',
          name: 'To Delete',
          repeatMode: 'forever',
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
        [
          RoutinePhasesCompanion.insert(
            id: 'phase-1',
            routineId: 'routine-to-delete',
            orderIndex: 0,
            name: 'Work',
            transitionPolicy: 'auto',
          ),
        ],
      );

      final deletedCount = await dao.deleteRoutine('routine-to-delete');
      expect(deletedCount, equals(1));

      final routine = await dao.getRoutineById('routine-to-delete');
      expect(routine, isNull);

      final phases = await dao.getPhasesForRoutine('routine-to-delete');
      expect(phases, isEmpty);
    });
  });
}
