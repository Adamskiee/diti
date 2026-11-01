import 'package:diti_database/diti_database.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

const List<String> _v4Schema = <String>[
  'CREATE TABLE "routines" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, '
      '"repeat_mode" TEXT NOT NULL, "repeat_count" INTEGER NULL, '
      '"created_at_utc" INTEGER NOT NULL, "updated_at_utc" INTEGER NOT NULL, '
      'PRIMARY KEY ("id"))',
  'CREATE TABLE "routine_phases" ("id" TEXT NOT NULL, "routine_id" TEXT NOT NULL '
      'REFERENCES routines (id) ON DELETE CASCADE, "order_index" INTEGER NOT NULL, '
      '"name" TEXT NOT NULL, "duration_ms" INTEGER NULL, '
      '"transition_policy" TEXT NOT NULL, "kind" TEXT NOT NULL DEFAULT \'focus\', '
      'PRIMARY KEY ("routine_id", "id"))',
  'CREATE TABLE "timer_runs" ("run_id" TEXT NOT NULL, "status" TEXT NOT NULL, '
      '"phase_status" TEXT NOT NULL, "current_phase_index" INTEGER NOT NULL, '
      '"repeat_index" INTEGER NOT NULL, "accumulated_ms" INTEGER NOT NULL, '
      '"phase_started_at_utc" INTEGER NOT NULL, "paused_at_utc" INTEGER NULL, '
      '"state_version" INTEGER NOT NULL, "last_event_id" TEXT NULL, '
      '"routine_snapshot_json" TEXT NOT NULL, '
      '"phase_ledger_json" TEXT NOT NULL DEFAULT \'[]\', '
      '"run_started_at_utc" INTEGER, "phase_first_started_at_utc" INTEGER, '
      'PRIMARY KEY ("run_id"))',
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
      '"outcome" TEXT NULL, "kind" TEXT NOT NULL DEFAULT \'focus\', '
      'PRIMARY KEY ("event_id"))',
  'CREATE TABLE "session_app_usages" ("id" TEXT NOT NULL, "session_id" TEXT NOT NULL '
      'REFERENCES sessions (session_id) ON DELETE CASCADE, "app_name" TEXT NOT NULL, '
      '"category" TEXT NOT NULL, "sample_title" TEXT NULL, '
      '"duration_ms" INTEGER NOT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "plan_blocks" ("id" TEXT NOT NULL, "plan_date" TEXT NOT NULL, '
      '"scheduled_start_utc" INTEGER NOT NULL, "timezone_id" TEXT NOT NULL, '
      '"planned_duration_ms" INTEGER NOT NULL, "routine_id" TEXT NULL, '
      '"actual_duration_ms" INTEGER NULL, "session_id" TEXT NULL, '
      '"status" TEXT NOT NULL, PRIMARY KEY ("id"))',
];

Database _openV4Database() {
  final raw = sqlite3.openInMemory();
  for (final statement in _v4Schema) {
    raw.execute(statement);
  }
  raw.execute('PRAGMA user_version = 4');
  return raw;
}

void main() {
  group('V4ToV5Migration', () {
    test('default migration registry resolves 4 -> 5 step', () {
      final steps = defaultMigrationRegistry.resolveSteps(4, 5);
      expect(steps.length, equals(1));
      expect(steps.single.fromVersion, equals(4));
      expect(steps.single.toVersion, equals(5));
    });

    test('creates activity_samples table and upgrades version to 5 on fresh DB', () async {
      final db = DitiDatabase(
        NativeDatabase.memory(),
        migrationRunner: MigrationRunner(defaultMigrationRegistry),
      );

      expect(db.schemaVersion, equals(5));

      await db.customStatement(
        "INSERT INTO activity_samples (id, sampled_at_utc, duration_ms, app_name, category, sample_title) "
        "VALUES ('sample-1', '2026-11-01T12:00:00Z', 3000, 'VS Code', 'Development', 'main.dart');",
      );

      final result = await db.customSelect('SELECT * FROM activity_samples').get();
      expect(result.length, equals(1));
      expect(result.first.data['app_name'], equals('VS Code'));

      await db.close();
    });

    test('migrates raw v4 database to v5 and creates activity_samples table', () async {
      final raw = _openV4Database();
      final db = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      addTearDown(() async {
        await db.close();
        raw.close();
      });

      // Insert into activity_samples to trigger migration and test table existence
      await db.customStatement(
        "INSERT INTO activity_samples (id, sampled_at_utc, duration_ms, app_name, category, sample_title) "
        "VALUES ('sample-migrated', '2026-11-01T12:00:00Z', 5000, 'Chrome', 'Browsing', 'Google');",
      );

      final result = await db.customSelect('SELECT * FROM activity_samples').get();
      expect(result.length, equals(1));
      expect(result.first.data['app_name'], equals('Chrome'));
      expect(raw.userVersion, equals(5));
    });
  });
}
