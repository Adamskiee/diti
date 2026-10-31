import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/diti_database.dart';

const List<String> _v2Schema = <String>[
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
  'CREATE TABLE "plan_blocks" ("id" TEXT NOT NULL, "plan_date" TEXT NOT NULL, '
      '"scheduled_start_utc" INTEGER NOT NULL, "timezone_id" TEXT NOT NULL, '
      '"planned_duration_ms" INTEGER NOT NULL, "routine_id" TEXT NULL, '
      '"actual_duration_ms" INTEGER NULL, "session_id" TEXT NULL, '
      '"status" TEXT NOT NULL, PRIMARY KEY ("id"))',
];

Database _openV2Database() {
  final raw = sqlite3.openInMemory();
  for (final statement in _v2Schema) {
    raw.execute(statement);
  }
  raw.execute(
    "INSERT INTO sessions (session_id, routine_id, plan_block_id, routine_name, "
    "started_at_utc, ended_at_utc, total_duration_ms, outcome, routine_snapshot_json) "
    "VALUES ('sess-v2-existing', NULL, NULL, 'Existing Routine', 1760000000, 1760003600, 3600000, 'completed', '{}')",
  );
  raw.execute('PRAGMA user_version = 2');
  return raw;
}

void main() {
  group('v2_to_v3_migration', () {
    test('creates session_app_usages table and bumps version to 3', () async {
      final db = DitiDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // Verify schemaVersion is 4
      expect(db.schemaVersion, equals(4));

      // Insert routine & session
      final sessionRecord = SessionRecord(
        sessionId: 'sess-v3-1',
        routineName: 'Deep Work',
        startedAtUtc: DateTime.utc(2026, 10, 26, 6, 0),
        endedAtUtc: DateTime.utc(2026, 10, 26, 7, 0),
        totalDurationMs: 3600000,
        outcome: SessionOutcome.completed,
        routineSnapshot: const Routine(
          id: 'r1',
          name: 'Deep Work',
          repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
          phases: [],
        ),
        appUsages: const [
          SessionAppUsageRecord(
            id: 'usage-1',
            sessionId: 'sess-v3-1',
            appName: 'Google Chrome',
            category: 'YouTube',
            sampleTitle: 'YouTube',
            durationMs: 1200000,
          ),
          SessionAppUsageRecord(
            id: 'usage-2',
            sessionId: 'sess-v3-1',
            appName: 'Terminal',
            category: 'Terminal',
            sampleTitle: 'Terminal',
            durationMs: 2400000,
          ),
        ],
      );

      final repo = DriftSessionRepository(db);
      await repo.saveSession(sessionRecord);

      final loaded = await repo.getSessionById('sess-v3-1');
      expect(loaded, isNotNull);
      expect(loaded!.appUsages.length, equals(2));
      expect(loaded.appUsages.first.category, equals('YouTube'));
      expect(loaded.appUsages.last.category, equals('Terminal'));
    });

    test('migrates raw v2 database to v3 preserving existing session rows', () async {
      final raw = _openV2Database();
      final db = DitiDatabase(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      addTearDown(() async {
        await db.close();
        raw.close();
      });

      // Query to trigger migration
      final existing = await db.customSelect('SELECT * FROM sessions WHERE session_id = ?', variables: [
        Variable.withString('sess-v2-existing'),
      ]).getSingle();
      expect(existing.data['routine_name'], equals('Existing Routine'));

      // Check user_version upgraded to 4
      expect(raw.userVersion, equals(4));

      // Verify table session_app_usages was created
      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='session_app_usages'",
      ).get();
      expect(tables.length, equals(1));

      // Insert app usage for existing session
      await db.sessionAppUsagesDao.insertUsages([
        const SessionAppUsagesCompanion(
          id: Value('usage-v2-migrated'),
          sessionId: Value('sess-v2-existing'),
          appName: Value('Xcode'),
          category: Value('Development'),
          sampleTitle: Value('Project'),
          durationMs: Value(1500000),
        ),
      ]);

      final usages = await db.sessionAppUsagesDao.getUsagesForSession('sess-v2-existing');
      expect(usages.length, equals(1));
      expect(usages.first.appName, equals('Xcode'));
    });

    test('default migration registry resolves 2 -> 3 step', () {
      final steps = defaultMigrationRegistry.resolveSteps(2, 3);
      expect(steps.length, equals(1));
      expect(steps.single, isA<V2ToV3Migration>());
      expect(steps.single.fromVersion, equals(2));
      expect(steps.single.toVersion, equals(3));
    });

    test('cascades delete from sessions to session_app_usages', () async {
      final db = DitiDatabase.inMemory();
      addTearDown(db.close);

      final repo = DriftSessionRepository(db);
      final sessionRecord = SessionRecord(
        sessionId: 'sess-cascade-test',
        routineName: 'Cascade Routine',
        startedAtUtc: DateTime.utc(2026, 10, 26, 6, 0),
        endedAtUtc: DateTime.utc(2026, 10, 26, 6, 30),
        totalDurationMs: 1800000,
        outcome: SessionOutcome.completed,
        routineSnapshot: const Routine(
          id: 'r-cascade',
          name: 'Cascade Routine',
          repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
          phases: [],
        ),
        appUsages: const [
          SessionAppUsageRecord(
            id: 'usage-cascade',
            sessionId: 'sess-cascade-test',
            appName: 'Slack',
            category: 'Communication',
            sampleTitle: 'General',
            durationMs: 300000,
          ),
        ],
      );

      await repo.saveSession(sessionRecord);
      var usages = await db.sessionAppUsagesDao.getUsagesForSession('sess-cascade-test');
      expect(usages.length, equals(1));

      await repo.deleteSession('sess-cascade-test');
      usages = await db.sessionAppUsagesDao.getUsagesForSession('sess-cascade-test');
      expect(usages, isEmpty);
    });
  });
}
