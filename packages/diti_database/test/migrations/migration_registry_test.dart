import 'package:test/test.dart';
import 'package:drift/drift.dart';
import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/database/migrations/migration_exceptions.dart';
import 'package:diti_database/src/database/migrations/migration_registry.dart';
import 'package:diti_database/src/database/migrations/schema_migration.dart';

class _MockStep implements SchemaMigration {
  @override
  final int fromVersion;
  @override
  final int toVersion;

  const _MockStep(this.fromVersion, this.toVersion);

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {}
}

void main() {
  group('MigrationRegistry', () {
    late MigrationRegistry registry;

    setUp(() {
      registry = MigrationRegistry();
    });

    test('registers and resolves a single contiguous migration step', () {
      registry.register(const _MockStep(1, 2));

      final steps = registry.resolveSteps(1, 2);
      expect(steps.length, equals(1));
      expect(steps.first.fromVersion, equals(1));
      expect(steps.first.toVersion, equals(2));
    });

    test('resolves multi-step chain in sequential order', () {
      registry.register(const _MockStep(2, 3));
      registry.register(const _MockStep(1, 2));

      final steps = registry.resolveSteps(1, 3);
      expect(steps.map((s) => '${s.fromVersion}->${s.toVersion}').toList(), [
        '1->2',
        '2->3',
      ]);
    });

    test('returns empty list when fromVersion == toVersion', () {
      final steps = registry.resolveSteps(1, 1);
      expect(steps, isEmpty);
    });

    test('throws UnsupportedError when fromVersion > toVersion (downgrade)',
        () {
      expect(
        () => registry.resolveSteps(2, 1),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('throws MigrationMissingException when an intermediate step is absent',
        () {
      registry.register(const _MockStep(1, 2));
      registry.register(const _MockStep(3, 4));

      expect(
        () => registry.resolveSteps(1, 4),
        throwsA(
          isA<MigrationMissingException>()
              .having((e) => e.fromVersion, 'fromVersion', 2)
              .having((e) => e.targetVersion, 'targetVersion', 3),
        ),
      );
    });

    test('rejects non-contiguous step registration (e.g. 1 -> 3)', () {
      expect(
        () => registry.register(const _MockStep(1, 3)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duplicate registration for the same fromVersion', () {
      registry.register(const _MockStep(1, 2));
      expect(
        () => registry.register(const _MockStep(1, 2)),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects non-positive version bounds', () {
      expect(
        () => registry.register(const _MockStep(0, 1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => registry.resolveSteps(0, 1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
