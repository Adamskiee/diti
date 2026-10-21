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
    await db.customStatement(
      "ALTER TABLE routine_phases ADD COLUMN kind TEXT NOT NULL DEFAULT 'focus'",
    );
    await db.customStatement(
      "ALTER TABLE timer_runs ADD COLUMN phase_ledger_json TEXT NOT NULL DEFAULT '[]'",
    );
    await db.customStatement(
      'ALTER TABLE timer_runs ADD COLUMN run_started_at_utc INTEGER',
    );
    await db.customStatement(
      'ALTER TABLE timer_runs ADD COLUMN phase_first_started_at_utc INTEGER',
    );
    await db.customStatement(
      "ALTER TABLE session_events ADD COLUMN kind TEXT NOT NULL DEFAULT 'focus'",
    );

    // Backfill rest-sounding phase names using the one shared rule.
    // PhaseKind.inferFromName is called directly rather than restating the
    // rule in SQL, so the migration and the editor can never disagree.
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
