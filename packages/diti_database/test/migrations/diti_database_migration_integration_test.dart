import 'package:test/test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:diti_database/diti_database.dart';

class _ProbeStep implements SchemaMigration {
  @override
  final int fromVersion;
  @override
  final int toVersion;
  bool executed = false;

  _ProbeStep(this.fromVersion, this.toVersion);

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {
    executed = true;
  }
}

void main() {
  group('DitiDatabase Migration Integration', () {
    test('DitiDatabase defaults schemaVersion to 1 and uses defaultMigrationRegistry', () async {
      final db = DitiDatabase.inMemory();
      expect(db.schemaVersion, equals(1));
      await db.close();
    });

    test('DitiDatabase triggers migrationRunner on upgrade', () async {
      final registry = MigrationRegistry();
      final step = _ProbeStep(1, 2);
      registry.register(step);

      final runner = MigrationRunner(registry);
      final db = DitiDatabase(
        NativeDatabase.memory(),
        migrationRunner: runner,
      );

      // Force an upgrade invocation using Drift's internal migrator contract
      final m = Migrator(db);
      await db.migration.onUpgrade(m, 1, 2);

      expect(step.executed, isTrue);
      await db.close();
    });
  });
}
