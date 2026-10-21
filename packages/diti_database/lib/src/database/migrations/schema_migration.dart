import 'package:drift/drift.dart';
import '../diti_database.dart';

/// Contract for an individual schema migration step between two versions.
abstract interface class SchemaMigration {
  /// The starting schema version this migration upgrades from.
  int get fromVersion;

  /// The target schema version this migration upgrades to.
  int get toVersion;

  /// Executes DDL changes and data transformations for this version step.
  Future<void> migrate(Migrator m, DitiDatabase db);
}
