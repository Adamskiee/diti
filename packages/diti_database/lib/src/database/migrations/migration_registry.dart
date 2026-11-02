import 'migration_exceptions.dart';
import 'schema_migration.dart';
import 'v1_to_v2_migration.dart';
import 'v2_to_v3_migration.dart';
import 'v3_to_v4_migration.dart';
import 'v4_to_v5_migration.dart';

/// Registry maintaining and validating schema migration steps.
class MigrationRegistry {
  final Map<int, SchemaMigration> _migrations = {};

  MigrationRegistry([List<SchemaMigration> migrations = const []]) {
    for (final migration in migrations) {
      register(migration);
    }
  }

  /// Registers a contiguous migration step (e.g. 1 -> 2).
  void register(SchemaMigration migration) {
    if (migration.fromVersion < 1) {
      throw ArgumentError(
        'Migration fromVersion must be >= 1, got ${migration.fromVersion}',
      );
    }
    if (migration.toVersion != migration.fromVersion + 1) {
      throw ArgumentError(
        'Migration step must be strictly contiguous: '
        'fromVersion=${migration.fromVersion}, toVersion=${migration.toVersion}',
      );
    }
    if (_migrations.containsKey(migration.fromVersion)) {
      throw StateError(
        'Duplicate migration registered for version ${migration.fromVersion}',
      );
    }
    _migrations[migration.fromVersion] = migration;
  }

  /// Resolves an ordered list of contiguous steps from [fromVersion] to [toVersion].
  List<SchemaMigration> resolveSteps(int fromVersion, int toVersion) {
    if (fromVersion < 1) {
      throw ArgumentError('fromVersion must be >= 1, got $fromVersion');
    }
    if (fromVersion > toVersion) {
      throw UnsupportedError(
        'Database downgrades are not supported (from: $fromVersion, to: $toVersion).',
      );
    }
    if (fromVersion == toVersion) {
      return const [];
    }

    final steps = <SchemaMigration>[];
    for (var v = fromVersion; v < toVersion; v++) {
      final step = _migrations[v];
      if (step == null) {
        throw MigrationMissingException(v, v + 1);
      }
      steps.add(step);
    }
    return List.unmodifiable(steps);
  }
}

/// The global default migration registry instance for DitiDatabase.
final defaultMigrationRegistry = MigrationRegistry()
  ..register(V1ToV2Migration())
  ..register(V2ToV3Migration())
  ..register(V3ToV4Migration())
  ..register(V4ToV5Migration());
