import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables/routines_table.dart';
import 'tables/routine_phases_table.dart';
import 'tables/timer_runs_table.dart';
import 'tables/timer_events_table.dart';
import 'tables/sessions_table.dart';
import 'tables/session_events_table.dart';
import 'tables/plan_blocks_table.dart';
import '../daos/routines_dao.dart';
import '../daos/timer_runs_dao.dart';
import '../daos/sessions_dao.dart';
import '../daos/plan_blocks_dao.dart';
import 'migrations/migration_runner.dart';
import 'migrations/migration_registry.dart';

part 'diti_database.g.dart';

typedef RoutineData = Routine;
typedef RoutinePhaseData = RoutinePhase;
typedef TimerRunData = TimerRun;
typedef TimerEventData = TimerEvent;
typedef SessionData = Session;
typedef SessionEventData = SessionEvent;
typedef PlanBlockData = PlanBlock;

@DriftDatabase(
  tables: [
    Routines,
    RoutinePhases,
    TimerRuns,
    TimerEvents,
    Sessions,
    SessionEvents,
    PlanBlocks,
  ],
  daos: [
    RoutinesDao,
    TimerRunsDao,
    SessionsDao,
    PlanBlocksDao,
  ],
)
class DitiDatabase extends _$DitiDatabase {
  final MigrationRunner? _customMigrationRunner;

  DitiDatabase(super.e, {MigrationRunner? migrationRunner})
      : _customMigrationRunner = migrationRunner;

  DitiDatabase.connect(super.e, {MigrationRunner? migrationRunner})
      : _customMigrationRunner = migrationRunner;

  DitiDatabase.inMemory({MigrationRunner? migrationRunner})
      : _customMigrationRunner = migrationRunner,
        super(NativeDatabase.memory());

  factory DitiDatabase.defaults({MigrationRunner? migrationRunner}) {
    return DitiDatabase(
      NativeDatabase.createInBackground(
        File('diti.db'),
      ),
      migrationRunner: migrationRunner,
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          final runner = _customMigrationRunner ?? MigrationRunner(defaultMigrationRegistry);
          await runner.upgrade(this, m, from, to);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
