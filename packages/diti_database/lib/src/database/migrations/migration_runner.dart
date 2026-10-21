import 'package:drift/drift.dart';
import '../diti_database.dart';
import 'migration_exceptions.dart';
import 'migration_registry.dart';

/// Coordinates executing resolved migration steps against [DitiDatabase].
class MigrationRunner {
  final MigrationRegistry registry;

  const MigrationRunner(this.registry);

  /// Executes contiguous schema upgrades from [from] to [to].
  Future<void> upgrade(DitiDatabase db, Migrator m, int from, int to) async {
    final steps = registry.resolveSteps(from, to);
    if (steps.isEmpty) return;

    // In SQLite, foreign keys MUST be disabled outside active transactions
    // before performing table rebuilds/alterations.
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    try {
      await db.transaction(() async {
        for (final step in steps) {
          await step.migrate(m, db);
        }

        // Verify referential integrity before committing the transaction.
        final violations = await db.customSelect('PRAGMA foreign_key_check;').get();
        if (violations.isNotEmpty) {
          final summary = violations.map((row) => row.data.toString()).toList();
          throw MigrationIntegrityException(summary);
        }
      });
    } finally {
      await db.customStatement('PRAGMA foreign_keys = ON;');
    }
  }
}
