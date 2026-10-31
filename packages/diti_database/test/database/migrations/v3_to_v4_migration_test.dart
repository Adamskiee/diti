import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:diti_database/diti_database.dart';

const List<String> _v3Schema = <String>[
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

Database _openV3Database() {
  final raw = sqlite3.openInMemory();
  for (final statement in _v3Schema) {
    raw.execute(statement);
  }
  raw.execute(
    "INSERT INTO sessions (session_id, routine_id, plan_block_id, routine_name, "
    "started_at_utc, ended_at_utc, total_duration_ms, outcome, routine_snapshot_json) "
    "VALUES ('sess-cancelled', 'routine-1', 'block-1', 'Cancelled Routine', 1760000000, 1760001000, 1000000, 'cancelled', '{}')",
  );
  raw.execute(
    "INSERT INTO sessions (session_id, routine_id, plan_block_id, routine_name, "
    "started_at_utc, ended_at_utc, total_duration_ms, outcome, routine_snapshot_json) "
    "VALUES ('sess-completed', 'routine-2', 'block-2', 'Completed Routine', 1760002000, 1760003000, 1000000, 'completed', '{}')",
  );
  raw.execute(
    "INSERT INTO plan_blocks (id, plan_date, scheduled_start_utc, timezone_id, planned_duration_ms, routine_id, actual_duration_ms, session_id, status) "
    "VALUES ('block-1', '2026-10-31', 1760000000, 'UTC', 1800000, 'routine-1', 1000000, 'sess-cancelled', 'cancelled')",
  );
  raw.execute(
    "INSERT INTO plan_blocks (id, plan_date, scheduled_start_utc, timezone_id, planned_duration_ms, routine_id, actual_duration_ms, session_id, status) "
    "VALUES ('block-2', '2026-10-31', 1760002000, 'UTC', 1800000, 'routine-2', 1000000, 'sess-completed', 'completed')",
  );
  raw.execute(
    "INSERT INTO plan_blocks (id, plan_date, scheduled_start_utc, timezone_id, planned_duration_ms, routine_id, actual_duration_ms, session_id, status) "
    "VALUES ('block-unlinked-cancelled', '2026-10-31', 1760004000, 'UTC', 1800000, 'routine-3', NULL, NULL, 'cancelled')",
  );
  raw.execute('PRAGMA user_version = 3');
  return raw;
}

void main() {
  group('v3_to_v4_migration', () {
    test('default migration registry resolves 3 -> 4 step', () {
      final steps = defaultMigrationRegistry.resolveSteps(3, 4);
      expect(steps.length, equals(1));
      expect(steps.single, isA<V3ToV4Migration>());
      expect(steps.single.fromVersion, equals(3));
      expect(steps.single.toVersion, equals(4));
    });

    test('migrates raw v3 database to v4 updating cancelled sessions and linked plan blocks to completed', () async {
      final raw = _openV3Database();
      final db = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      addTearDown(() async {
        await db.close();
        raw.close();
      });

      // Query to trigger migration
      final cancelledSession = await db.customSelect(
        'SELECT * FROM sessions WHERE session_id = ?',
        variables: [Variable.withString('sess-cancelled')],
      ).getSingle();
      expect(cancelledSession.data['outcome'], equals('completed'));

      final completedSession = await db.customSelect(
        'SELECT * FROM sessions WHERE session_id = ?',
        variables: [Variable.withString('sess-completed')],
      ).getSingle();
      expect(completedSession.data['outcome'], equals('completed'));

      final linkedBlock = await db.customSelect(
        'SELECT * FROM plan_blocks WHERE id = ?',
        variables: [Variable.withString('block-1')],
      ).getSingle();
      expect(linkedBlock.data['status'], equals('completed'));

      final completedBlock = await db.customSelect(
        'SELECT * FROM plan_blocks WHERE id = ?',
        variables: [Variable.withString('block-2')],
      ).getSingle();
      expect(completedBlock.data['status'], equals('completed'));

      final unlinkedBlock = await db.customSelect(
        'SELECT * FROM plan_blocks WHERE id = ?',
        variables: [Variable.withString('block-unlinked-cancelled')],
      ).getSingle();
      expect(unlinkedBlock.data['status'], equals('cancelled'));

      // Verify PRAGMA user_version was upgraded to 4
      expect(raw.userVersion, equals(4));
    });
  });
}
