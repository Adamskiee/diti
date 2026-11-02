import 'package:test/test.dart';
import 'package:drift/drift.dart';
import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/database/migrations/migration_exceptions.dart';
import 'package:diti_database/src/database/migrations/migration_registry.dart';
import 'package:diti_database/src/database/migrations/migration_runner.dart';
import 'package:diti_database/src/database/migrations/schema_migration.dart';

class _ExecutableStep implements SchemaMigration {
  @override
  final int fromVersion;
  @override
  final int toVersion;
  final Future<void> Function(Migrator m, DitiDatabase db) action;

  const _ExecutableStep(this.fromVersion, this.toVersion, this.action);

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) => action(m, db);
}

void main() {
  group('MigrationRunner', () {
    late DitiDatabase db;
    late MigrationRegistry registry;
    late MigrationRunner runner;

    setUp(() {
      db = DitiDatabase.inMemory();
      registry = MigrationRegistry();
      runner = MigrationRunner(registry);
    });

    tearDown(() async {
      await db.close();
    });

    test('no-op when from == to', () async {
      final m = Migrator(db);
      await runner.upgrade(db, m, 1, 1);
      // Completes with no error
    });

    test('executes registered steps in sequence', () async {
      final executionOrder = <int>[];

      registry.register(_ExecutableStep(1, 2, (m, database) async {
        executionOrder.add(1);
      }));
      registry.register(_ExecutableStep(2, 3, (m, database) async {
        executionOrder.add(2);
      }));

      final m = Migrator(db);
      await runner.upgrade(db, m, 1, 3);

      expect(executionOrder, equals([1, 2]));
    });

    test('rolls back entire transaction on step error', () async {
      registry.register(_ExecutableStep(1, 2, (m, database) async {
        await database.customStatement(
            'CREATE TABLE test_rollback (id TEXT PRIMARY KEY);');
        throw Exception('Simulated failure during migration');
      }));

      final m = Migrator(db);
      expect(
        () => runner.upgrade(db, m, 1, 2),
        throwsA(isA<Exception>()),
      );

      // Verify test_rollback table does not exist due to rollback
      final checkTable = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='test_rollback';",
          )
          .get();
      expect(checkTable, isEmpty);
    });

    test(
        'detects foreign key violation and rolls back with MigrationIntegrityException',
        () async {
      registry.register(_ExecutableStep(1, 2, (m, database) async {
        // Insert orphaned routine phase referencing non-existent routine
        await database.customStatement(
          "INSERT INTO routine_phases (id, routine_id, order_index, name, transition_policy) "
          "VALUES ('p1', 'non_existent_routine', 0, 'Phase 1', 'auto');",
        );
      }));

      final m = Migrator(db);
      expect(
        () => runner.upgrade(db, m, 1, 2),
        throwsA(isA<MigrationIntegrityException>()),
      );

      // Verify phase was rolled back
      final phases =
          await db.customSelect("SELECT * FROM routine_phases;").get();
      expect(phases, isEmpty);
    });
  });
}
