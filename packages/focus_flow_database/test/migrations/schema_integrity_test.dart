import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:focus_flow_database/src/database/focus_flow_database.dart';

void main() {
  late FocusFlowDatabase database;

  setUp(() {
    database = FocusFlowDatabase.inMemory();
  });

  tearDown(() async {
    await database.close();
  });

  group('Schema Integrity & SQLite Pragmas', () {
    test('database boots with schemaVersion 1', () {
      expect(database.schemaVersion, equals(1));
    });

    test('enforces foreign key constraints: rejecting orphaned child rows', () async {
      // Trying to insert RoutinePhase referencing non-existent Routine ID must fail
      expect(
        () async => database.into(database.routinePhases).insert(
              RoutinePhasesCompanion.insert(
                id: 'phase-orphaned',
                routineId: 'non-existent-routine',
                orderIndex: 0,
                name: 'Orphaned Phase',
                transitionPolicy: 'auto',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('foreign key cascade deletes child routine phases when routine is deleted', () async {
      final now = DateTime.now().toUtc();
      await database.into(database.routines).insert(
            RoutinesCompanion.insert(
              id: 'routine-parent',
              name: 'Parent Routine',
              repeatMode: 'count',
              repeatCount: const Value(1),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      await database.into(database.routinePhases).insert(
            RoutinePhasesCompanion.insert(
              id: 'child-phase',
              routineId: 'routine-parent',
              orderIndex: 0,
              name: 'Child Phase',
              transitionPolicy: 'auto',
            ),
          );

      // Verify phase is present
      final phasesBefore = await (database.select(database.routinePhases)
            ..where((tbl) => tbl.routineId.equals('routine-parent')))
          .get();
      expect(phasesBefore.length, equals(1));

      // Delete parent routine
      await (database.delete(database.routines)
            ..where((tbl) => tbl.id.equals('routine-parent')))
          .go();

      // Verify child phase was cascade deleted
      final phasesAfter = await (database.select(database.routinePhases)
            ..where((tbl) => tbl.routineId.equals('routine-parent')))
          .get();
      expect(phasesAfter, isEmpty);
    });
  });
}
