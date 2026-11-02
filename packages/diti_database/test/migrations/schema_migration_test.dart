import 'package:test/test.dart';
import 'package:drift/drift.dart';
import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/database/migrations/migration_exceptions.dart';
import 'package:diti_database/src/database/migrations/schema_migration.dart';

class _FakeMigration implements SchemaMigration {
  @override
  final int fromVersion;
  @override
  final int toVersion;

  _FakeMigration({
    required this.fromVersion,
    required this.toVersion,
  });

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {}
}

void main() {
  group('Migration Exceptions', () {
    test('MigrationMissingException formats message correctly', () {
      final exception = MigrationMissingException(1, 2);
      expect(
        exception.toString(),
        contains('Missing migration step from version 1 to 2'),
      );
      expect(exception.fromVersion, equals(1));
      expect(exception.targetVersion, equals(2));
    });

    test('MigrationIntegrityException formats violations correctly', () {
      final violations = [
        'table routines has orphaned child in routine_phases'
      ];
      final exception = MigrationIntegrityException(violations);
      expect(
          exception.toString(), contains('Foreign key integrity check failed'));
      expect(exception.violations, equals(violations));
    });
  });

  group('SchemaMigration Interface', () {
    test('instantiates and provides version bounds', () {
      final migration = _FakeMigration(fromVersion: 1, toVersion: 2);
      expect(migration.fromVersion, equals(1));
      expect(migration.toVersion, equals(2));
    });
  });
}
