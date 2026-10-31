import 'package:diti_database/src/database/diti_database.dart';
import 'package:diti_database/src/database/migrations/migration_registry.dart';
import 'package:diti_database/src/database/migrations/v1_to_v2_migration.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// The schema of the database at version 1, frozen exactly as `DitiDatabase`
/// created it before the per-phase columns existed.
///
/// The step has to run against a real v1 database: `DitiDatabase.inMemory()`
/// builds the *current* schema, so `ALTER TABLE ... ADD COLUMN` would fail
/// with "duplicate column name" and the backfill would never see a v1 row.
const List<String> _v1Schema = <String>[
  'CREATE TABLE "routines" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, '
      '"repeat_mode" TEXT NOT NULL, "repeat_count" INTEGER NULL, '
      '"created_at_utc" INTEGER NOT NULL, "updated_at_utc" INTEGER NOT NULL, '
      'PRIMARY KEY ("id"))',
  'CREATE TABLE "routine_phases" ("id" TEXT NOT NULL, "routine_id" TEXT NOT NULL '
      'REFERENCES routines (id) ON DELETE CASCADE, "order_index" INTEGER NOT NULL, '
      '"name" TEXT NOT NULL, "duration_ms" INTEGER NULL, '
      '"transition_policy" TEXT NOT NULL, PRIMARY KEY ("routine_id", "id"))',
  'CREATE TABLE "timer_runs" ("run_id" TEXT NOT NULL, "status" TEXT NOT NULL, '
      '"phase_status" TEXT NOT NULL, "current_phase_index" INTEGER NOT NULL, '
      '"repeat_index" INTEGER NOT NULL, "accumulated_ms" INTEGER NOT NULL, '
      '"phase_started_at_utc" INTEGER NOT NULL, "paused_at_utc" INTEGER NULL, '
      '"state_version" INTEGER NOT NULL, "last_event_id" TEXT NULL, '
      '"routine_snapshot_json" TEXT NOT NULL, PRIMARY KEY ("run_id"))',
  'CREATE TABLE "timer_events" ("event_id" TEXT NOT NULL, "run_id" TEXT NOT NULL '
      'REFERENCES timer_runs (run_id) ON DELETE CASCADE, "event_type" TEXT NOT NULL, '
      '"occurred_at_utc" INTEGER NOT NULL, "duration_ms" INTEGER NOT NULL DEFAULT 0, '
      '"metadata_json" TEXT NOT NULL DEFAULT \'{}\', PRIMARY KEY ("event_id"))',
  'CREATE TABLE "sessions" ("session_id" TEXT NOT NULL, "routine_id" TEXT NULL, '
      '"plan_block_id" TEXT NULL, "routine_name" TEXT NOT NULL, '
      '"started_at_utc" INTEGER NOT NULL, "ended_at_utc" INTEGER NOT NULL, '
      '"total_duration_ms" INTEGER NOT NULL, "outcome" TEXT NOT NULL, '
      '"routine_snapshot_json" TEXT NOT NULL, PRIMARY KEY ("session_id"))',
  'CREATE TABLE "session_events" ("event_id" TEXT NOT NULL, "session_id" TEXT NOT NULL '
      'REFERENCES sessions (session_id) ON DELETE CASCADE, "event_type" TEXT NOT NULL, '
      '"occurred_at_utc" INTEGER NOT NULL, "phase_id" TEXT NULL, '
      '"phase_name" TEXT NULL, "duration_ms" INTEGER NOT NULL DEFAULT 0, '
      '"outcome" TEXT NULL, PRIMARY KEY ("event_id"))',
  'CREATE TABLE "plan_blocks" ("id" TEXT NOT NULL, "plan_date" TEXT NOT NULL, '
      '"scheduled_start_utc" INTEGER NOT NULL, "timezone_id" TEXT NOT NULL, '
      '"planned_duration_ms" INTEGER NOT NULL, "routine_id" TEXT NULL, '
      '"actual_duration_ms" INTEGER NULL, "session_id" TEXT NULL, '
      '"status" TEXT NOT NULL, PRIMARY KEY ("id"))',
];

/// A version 1 routine snapshot: it predates the per-phase `kind` tag.
const String _v1Snapshot = '{"schemaVersion":1,"id":"routine-1",'
    '"name":"Morning Routine","repeatRule":{"mode":"count","count":3},'
    '"phases":[{"id":"phase-focus","name":"Focus","durationMs":1500000,'
    '"transition":"auto"},{"id":"phase-break","name":"Short Break",'
    '"durationMs":300000,"transition":"auto"}]}';

/// The rows an existing user would already have when the app updates.
const List<String> _v1Rows = <String>[
  "INSERT INTO routines (id, name, repeat_mode, repeat_count, created_at_utc, "
      "updated_at_utc) VALUES "
      "('routine-1', 'Morning Routine', 'count', 3, 1760000000, 1760000000)",
  "INSERT INTO routine_phases (id, routine_id, order_index, name, duration_ms, "
      "transition_policy) VALUES "
      "('phase-focus', 'routine-1', 0, 'Focus', 1500000, 'auto')",
  "INSERT INTO routine_phases (id, routine_id, order_index, name, duration_ms, "
      "transition_policy) VALUES "
      "('phase-break', 'routine-1', 1, 'Short Break', 300000, 'auto')",
  "INSERT INTO routine_phases (id, routine_id, order_index, name, duration_ms, "
      "transition_policy) VALUES "
      "('phase-cooldown', 'routine-1', 2, 'Cooldown', 600000, 'manual')",
  "INSERT INTO routine_phases (id, routine_id, order_index, name, duration_ms, "
      "transition_policy) VALUES "
      "('phase-reading', 'routine-1', 3, 'Reading', 900000, 'auto')",
  "INSERT INTO routine_phases (id, routine_id, order_index, name, duration_ms, "
      "transition_policy) VALUES "
      "('phase-interest', 'routine-1', 4, 'Interest', 120000, 'auto')",
  "INSERT INTO plan_blocks (id, plan_date, scheduled_start_utc, timezone_id, "
      "planned_duration_ms, routine_id, actual_duration_ms, session_id, status) "
      "VALUES "
      "('plan-1', '2026-10-21', 1760000000, 'UTC', 1800000, 'routine-1', NULL, "
      "NULL, 'scheduled')",
  "INSERT INTO sessions (session_id, routine_id, plan_block_id, routine_name, "
      "started_at_utc, ended_at_utc, total_duration_ms, outcome, "
      "routine_snapshot_json) VALUES "
      "('session-1', 'routine-1', 'plan-1', 'Morning Routine', 1760000000, "
      "1760001500, 1500000, 'completed', '$_v1Snapshot')",
  "INSERT INTO session_events (event_id, session_id, event_type, occurred_at_utc, "
      "phase_id, phase_name, duration_ms, outcome) VALUES "
      "('session-event-1', 'session-1', 'phaseCompleted', 1760001500, "
      "'phase-break', 'Short Break', 300000, 'completed')",
  "INSERT INTO timer_runs (run_id, status, phase_status, current_phase_index, "
      "repeat_index, accumulated_ms, phase_started_at_utc, paused_at_utc, "
      "state_version, last_event_id, routine_snapshot_json) VALUES "
      "('run-1', 'running', 'active', 1, 0, 300000, 1760000000, NULL, 7, NULL, "
      "'$_v1Snapshot')",
  "INSERT INTO timer_events (event_id, run_id, event_type, occurred_at_utc, "
      "duration_ms, metadata_json) VALUES "
      "('timer-event-1', 'run-1', 'phaseStarted', 1760000000, 0, '{}')",
];

/// Builds a v1 database and opens it through drift, which sees
/// `user_version` 1 against schema version 2 and therefore runs the upgrade.
Future<DitiDatabase> _openMigratedDatabase() async {
  final raw = _openV1Database();
  final db = DitiDatabase(NativeDatabase.opened(raw));

  // The first query opens the connection, which triggers the migration.
  await db.customSelect('SELECT 1').get();

  return db;
}

/// A v1 database with the rows an existing user would already have.
Database _openV1Database() {
  final raw = sqlite3.openInMemory();
  for (final statement in _v1Schema) {
    raw.execute(statement);
  }
  for (final statement in _v1Rows) {
    raw.execute(statement);
  }
  raw.execute('PRAGMA user_version = 1');
  return raw;
}

/// The column names of [table] after the migration.
Future<List<String>> _columnNames(DitiDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toList();
}

/// The column layout of [table]: name, type, not-null, default and key
/// position — the shape a reader of the schema sees.
Future<List<String>> _columnLayout(DitiDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows
      .map((row) => [
            row.read<String>('name'),
            row.read<String>('type'),
            row.read<int>('notnull').toString(),
            row.data['dflt_value'] as String? ?? '<none>',
            row.read<int>('pk').toString(),
          ].join('|'))
      .toList();
}

/// Every table of the schema.
const List<String> _tables = <String>[
  'routines',
  'routine_phases',
  'timer_runs',
  'timer_events',
  'sessions',
  'session_events',
  'plan_blocks',
];

void main() {
  group('V1ToV2Migration', () {
    late DitiDatabase db;

    setUp(() async {
      db = await _openMigratedDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('the migration adds the kind, ledger and timestamp columns', () async {
      expect(await _columnNames(db, 'routine_phases'), contains('kind'));
      expect(
        await _columnNames(db, 'timer_runs'),
        containsAll(<String>[
          'phase_ledger_json',
          'run_started_at_utc',
          'phase_first_started_at_utc',
        ]),
      );
      expect(await _columnNames(db, 'session_events'), contains('kind'));
    });

    test('phases added after the migration default to focus', () async {
      await db.into(db.routinePhases).insert(
            RoutinePhasesCompanion.insert(
              id: 'phase-added-later',
              routineId: 'routine-1',
              orderIndex: 5,
              name: 'Deep Work',
              transitionPolicy: 'auto',
            ),
          );

      final added = await (db.select(db.routinePhases)
            ..where((t) => t.id.equals('phase-added-later')))
          .getSingle();
      expect(added.kind, equals('focus'));
    });

    test('the migration backfills kind from the phase name', () async {
      final phases = await db.select(db.routinePhases).get();
      final kinds = <String, String>{
        for (final phase in phases) phase.name: phase.kind,
      };

      expect(kinds['Focus'], equals('focus'));
      expect(kinds['Short Break'], equals('rest'));
      expect(kinds['Cooldown'], equals('rest'));
      expect(kinds['Reading'], equals('focus'));
      // "Interest" contains "rest" but is an ordinary focus phase.
      expect(kinds['Interest'], equals('focus'));
    });

    test('the migration preserves existing rows', () async {
      final routines = await db.select(db.routines).get();
      expect(routines.length, equals(1));
      expect(routines.first.id, equals('routine-1'));
      expect(routines.first.name, equals('Morning Routine'));
      expect(routines.first.repeatMode, equals('count'));
      expect(routines.first.repeatCount, equals(3));
      expect(
        routines.first.createdAtUtc.millisecondsSinceEpoch,
        equals(1760000000 * 1000),
      );

      final phases = await db.select(db.routinePhases).get();
      expect(phases.length, equals(5));
      final phase = phases.firstWhere((p) => p.id == 'phase-break');
      expect(phase.routineId, equals('routine-1'));
      expect(phase.orderIndex, equals(1));
      expect(phase.name, equals('Short Break'));
      expect(phase.durationMs, equals(300000));
      expect(phase.transitionPolicy, equals('auto'));

      final planBlocks = await db.select(db.planBlocks).get();
      expect(planBlocks.length, equals(1));
      expect(planBlocks.first.id, equals('plan-1'));
      expect(planBlocks.first.planDate, equals('2026-10-21'));
      expect(planBlocks.first.timezoneId, equals('UTC'));
      expect(planBlocks.first.plannedDurationMs, equals(1800000));
      expect(planBlocks.first.routineId, equals('routine-1'));
      expect(planBlocks.first.status, equals('scheduled'));

      final sessions = await db.select(db.sessions).get();
      expect(sessions.length, equals(1));
      expect(sessions.first.sessionId, equals('session-1'));
      expect(sessions.first.routineId, equals('routine-1'));
      expect(sessions.first.planBlockId, equals('plan-1'));
      expect(sessions.first.totalDurationMs, equals(1500000));
      expect(sessions.first.outcome, equals('completed'));
      expect(sessions.first.routineSnapshotJson, equals(_v1Snapshot));

      final sessionEvents = await db.select(db.sessionEvents).get();
      expect(sessionEvents.length, equals(1));
      expect(sessionEvents.first.eventId, equals('session-event-1'));
      expect(sessionEvents.first.sessionId, equals('session-1'));
      expect(sessionEvents.first.phaseName, equals('Short Break'));
      expect(sessionEvents.first.durationMs, equals(300000));
      // Events that existed before the migration keep the focus default.
      expect(sessionEvents.first.kind, equals('focus'));

      final timerEvents = await db.select(db.timerEvents).get();
      expect(timerEvents.length, equals(1));
      expect(timerEvents.first.eventId, equals('timer-event-1'));
      expect(timerEvents.first.runId, equals('run-1'));
    });

    test(
        'the migration leaves existing runs with an empty ledger and null timestamps',
        () async {
      final runs = await db.select(db.timerRuns).get();
      expect(runs.length, equals(1));
      expect(runs.first.runId, equals('run-1'));
      expect(runs.first.phaseLedgerJson, equals('[]'));
      expect(runs.first.runStartedAtUtc, isNull);
      expect(runs.first.phaseFirstStartedAtUtc, isNull);

      // The three new columns must not have disturbed the columns the row
      // already had.
      expect(runs.first.status, equals('running'));
      expect(runs.first.accumulatedMs, equals(300000));
      expect(runs.first.stateVersion, equals(7));
      expect(
        runs.first.phaseStartedAtUtc.millisecondsSinceEpoch,
        equals(1760000000 * 1000),
      );
    });
  });

  group('schema version', () {
    test('the database declares schema version 4', () async {
      final db = DitiDatabase.inMemory();
      expect(db.schemaVersion, equals(4));
      await db.close();
    });

    test('the default registry resolves the 1 -> 2 step', () {
      final steps = defaultMigrationRegistry.resolveSteps(1, 2);

      expect(steps.length, equals(1));
      expect(steps.single, isA<V1ToV2Migration>());
      expect(steps.single.fromVersion, equals(1));
      expect(steps.single.toVersion, equals(2));
    });

    test('re-opening the migrated database does not run the step again',
        () async {
      final raw = _openV1Database();

      final first = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await first.customSelect('SELECT 1').get();
      await first.close();

      // Drift records the new version, so the next launch skips the step
      // instead of failing on "duplicate column name".
      expect(raw.userVersion, equals(4));

      final second = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await second.customSelect('SELECT 1').get();

      final phases = await second.select(second.routinePhases).get();
      expect(phases.length, equals(5));
      expect(
        phases.firstWhere((p) => p.name == 'Short Break').kind,
        equals('rest'),
      );

      await second.close();
      raw.close();
    });

    test('the step survives a re-run after a crash before the version was written',
        () async {
      final raw = _openV1Database();

      final first = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await first.customSelect('SELECT 1').get();
      await first.close();

      // A process kill between the migration's commit and drift's
      // `PRAGMA user_version = 2` leaves the columns in place but the
      // version at 1. The next launch re-runs the step, which must not die
      // on "duplicate column name".
      raw.userVersion = 1;

      final second = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await second.customSelect('SELECT 1').get();

      final phases = await second.select(second.routinePhases).get();
      expect(phases.length, equals(5));
      expect(
        phases.firstWhere((p) => p.name == 'Short Break').kind,
        equals('rest'),
      );

      await second.close();
      raw.close();
    });

    test('the migrated schema matches a freshly created version 2 schema',
        () async {
      // This compares `PRAGMA table_info` for every table: the column
      // names, types, not-null flags, defaults and key positions. It does
      // not compare foreign-key clauses, indexes or the raw DDL text, so it
      // is not a full schema assertion.
      //
      // The schema a brand new database gets.
      final fresh = DitiDatabase.inMemory();
      await fresh.customSelect('SELECT 1').get();
      final freshLayouts = <String, List<String>>{};
      for (final table in _tables) {
        freshLayouts[table] = await _columnLayout(fresh, table);
      }
      await fresh.close();

      // The schema the migrated database ends up with.
      final migrated = await _openMigratedDatabase();
      for (final table in _tables) {
        expect(
          await _columnLayout(migrated, table),
          equals(freshLayouts[table]),
          reason: 'the migrated "$table" differs from a fresh version 2 table',
        );
      }
      await migrated.close();
    });
  });
}
