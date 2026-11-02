import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../database/tables/timer_runs_table.dart';
import '../database/tables/timer_events_table.dart';

part 'timer_runs_dao.g.dart';

@DriftAccessor(tables: [TimerRuns, TimerEvents])
class TimerRunsDao extends DatabaseAccessor<DitiDatabase>
    with _$TimerRunsDaoMixin {
  TimerRunsDao(super.db);

  Future<void> upsertRun(TimerRunsCompanion run) {
    return into(timerRuns).insertOnConflictUpdate(run);
  }

  Future<void> insertEvents(List<TimerEventsCompanion> events) async {
    await batch((batch) {
      batch.insertAll(timerEvents, events, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<TimerRunData?> getLatestActiveRun() {
    return (select(timerRuns)
          ..where((r) => r.status.isIn(['running', 'paused']))
          ..orderBy([(r) => OrderingTerm.desc(r.phaseStartedAtUtc)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<TimerEventData>> getEventsForRun(String runId) {
    return (select(timerEvents)
          ..where((e) => e.runId.equals(runId))
          ..orderBy([(e) => OrderingTerm.asc(e.occurredAtUtc)]))
        .get();
  }

  Future<int> deleteRun(String runId) {
    return (delete(timerRuns)..where((r) => r.runId.equals(runId))).go();
  }
}
