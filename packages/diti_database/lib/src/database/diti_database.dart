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
  DitiDatabase(super.e);

  DitiDatabase.connect(super.e);

  DitiDatabase.inMemory() : super(NativeDatabase.memory());

  factory DitiDatabase.defaults() {
    return DitiDatabase(
      NativeDatabase.createInBackground(
        File('diti.db'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
