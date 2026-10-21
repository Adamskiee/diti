import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:diti_database/diti_database.dart';

class _AddSettingsColumnMigration implements SchemaMigration {
  @override
  int get fromVersion => 1;
  @override
  int get toVersion => 2;

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {
    // Simulate adding an auxiliary table or column during an upgrade
    await db.customStatement(
      'CREATE TABLE app_meta (key TEXT PRIMARY KEY, val TEXT NOT NULL);',
    );
    await db.customStatement(
      "INSERT INTO app_meta (key, val) VALUES ('migrated', 'true');",
    );
  }
}

void main() {
  group('Data Preservation Across Migration', () {
    late DitiDatabase db;

    setUp(() {
      db = DitiDatabase.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('preserves all rows, relations, and timestamps across schema upgrades', () async {
      final now = DateTime.utc(2026, 10, 21, 10, 0, 0);

      // 1. Populate seed data across tables in v1
      await db.into(db.routines).insert(
            RoutinesCompanion.insert(
              id: 'routine-1',
              name: 'Morning Routine',
              repeatMode: 'count',
              repeatCount: const Value(3),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      await db.into(db.routinePhases).insert(
            RoutinePhasesCompanion.insert(
              id: 'phase-1',
              routineId: 'routine-1',
              orderIndex: 0,
              name: 'Meditation',
              transitionPolicy: 'auto',
            ),
          );

      await db.into(db.planBlocks).insert(
            PlanBlocksCompanion.insert(
              id: 'plan-1',
              planDate: '2026-10-21',
              scheduledStartUtc: now,
              timezoneId: 'UTC',
              plannedDurationMs: 1800000,
              routineId: const Value('routine-1'),
              status: 'scheduled',
            ),
          );

      await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              sessionId: 'session-1',
              routineId: const Value('routine-1'),
              routineName: 'Morning Routine Session',
              startedAtUtc: now,
              endedAtUtc: now.add(const Duration(minutes: 25)),
              totalDurationMs: 1500000,
              outcome: 'completed',
              routineSnapshotJson: '{}',
            ),
          );

      // 2. Execute migration runner for v1 -> v2
      final registry = MigrationRegistry([_AddSettingsColumnMigration()]);
      final runner = MigrationRunner(registry);
      final m = Migrator(db);

      await runner.upgrade(db, m, 1, 2);

      // 3. Verify new schema is active
      final metaRows = await db.customSelect('SELECT * FROM app_meta;').get();
      expect(metaRows.length, equals(1));
      expect(metaRows.first.data['val'], equals('true'));

      // 4. Verify all pre-existing rows remain completely intact
      final routines = await db.select(db.routines).get();
      expect(routines.length, equals(1));
      expect(routines.first.id, equals('routine-1'));
      expect(routines.first.name, equals('Morning Routine'));
      expect(routines.first.repeatCount, equals(3));
      expect(routines.first.createdAtUtc.toUtc(), equals(now));

      final phases = await db.select(db.routinePhases).get();
      expect(phases.length, equals(1));
      expect(phases.first.id, equals('phase-1'));
      expect(phases.first.routineId, equals('routine-1'));

      final plans = await db.select(db.planBlocks).get();
      expect(plans.length, equals(1));
      expect(plans.first.id, equals('plan-1'));
      expect(plans.first.status, equals('scheduled'));

      final sessions = await db.select(db.sessions).get();
      expect(sessions.length, equals(1));
      expect(sessions.first.sessionId, equals('session-1'));
      expect(sessions.first.totalDurationMs, equals(1500000));
    });
  });
}
