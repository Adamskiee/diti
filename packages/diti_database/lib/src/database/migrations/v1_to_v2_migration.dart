import 'package:drift/drift.dart';
import 'package:timer_engine/timer_engine.dart';
import '../diti_database.dart' hide Routine, RoutinePhase, TimerRun, TimerEvent;
import 'schema_migration.dart';

/// Migrates the database from schema version 1 to version 2.
///
/// The step is additive: it adds the per-phase `kind` column, the run's
/// phase ledger and the two run timestamps, and backfills `kind` from the
/// existing phase names. No table is rebuilt and no row is dropped.
class V1ToV2Migration implements SchemaMigration {
  @override
  int get fromVersion => 1;

  @override
  int get toVersion => 2;

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {
    // The migrator's own schema APIs are deliberately not used here: the
    // step has to stay purely additive, and a drift table rebuild would
    // drop the rows the step is meant to preserve.
    final addedKind = await _addColumn(
      db,
      table: 'routine_phases',
      column: 'kind',
      definition: "TEXT NOT NULL DEFAULT 'focus'",
    );
    await _addColumn(
      db,
      table: 'timer_runs',
      column: 'phase_ledger_json',
      definition: "TEXT NOT NULL DEFAULT '[]'",
    );
    await _addColumn(
      db,
      table: 'timer_runs',
      column: 'run_started_at_utc',
      definition: 'INTEGER',
    );
    await _addColumn(
      db,
      table: 'timer_runs',
      column: 'phase_first_started_at_utc',
      definition: 'INTEGER',
    );
    await _addColumn(
      db,
      table: 'session_events',
      column: 'kind',
      definition: "TEXT NOT NULL DEFAULT 'focus'",
    );

    // The backfill belongs to the column it fills: if the column was
    // already there, an earlier run has done the work.
    if (addedKind) {
      await _backfillKinds(db);
    }
  }

  /// Adds [column] to [table] unless the table already has that column.
  ///
  /// The step must survive a re-run: drift writes `PRAGMA user_version = 2`
  /// only after this migration has been committed, so a process kill in
  /// between leaves a database that has the columns but still claims to be
  /// version 1. The next launch runs the step again, and without this
  /// check it would die on "duplicate column name" and the app could not
  /// open its database at all.
  ///
  /// Returns whether this call added the column.
  Future<bool> _addColumn(
    DitiDatabase db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.customSelect('PRAGMA table_info($table)').get();
    final exists = columns.any((row) => row.read<String>('name') == column);
    if (exists) return false;

    await db
        .customStatement('ALTER TABLE $table ADD COLUMN $column $definition');
    return true;
  }

  /// Backfills rest-sounding phase names using the one shared rule.
  /// PhaseKind.inferFromName is called directly rather than restating the
  /// rule in SQL, so the migration and the editor can never disagree.
  Future<void> _backfillKinds(DitiDatabase db) async {
    final rows = await db
        .customSelect('SELECT id, routine_id, name FROM routine_phases')
        .get();
    for (final row in rows) {
      if (PhaseKind.inferFromName(row.read<String>('name')) != PhaseKind.rest) {
        continue;
      }
      await db.customUpdate(
        "UPDATE routine_phases SET kind = 'rest' WHERE id = ? AND routine_id = ?",
        variables: [
          Variable<String>(row.read<String>('id')),
          Variable<String>(row.read<String>('routine_id')),
        ],
      );
    }
  }
}
