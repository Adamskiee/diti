import 'package:drift/drift.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:focus_flow_database/src/database/focus_flow_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent;
import 'package:focus_flow_database/src/daos/timer_runs_dao.dart';
import 'package:focus_flow_database/src/mappers/snapshot_serializer.dart';

class DriftRunPersistencePort implements RunPersistencePort {
  final FocusFlowDatabase database;
  final TimerRunsDao dao;

  DriftRunPersistencePort(this.database) : dao = TimerRunsDao(database);

  @override
  Future<void> persistRunAndEvents(TimerRun run, List<TimerEvent> events) async {
    try {
      await database.transaction(() async {
        final runCompanion = TimerRunsCompanion(
          runId: Value(run.runId),
          status: Value(run.status.name),
          phaseStatus: Value(run.phaseStatus.name),
          currentPhaseIndex: Value(run.currentPhaseIndex),
          repeatIndex: Value(run.repeatIndex),
          accumulatedMs: Value(run.accumulatedMs),
          phaseStartedAtUtc: Value(run.phaseStartedAtUtc),
          pausedAtUtc: Value(run.pausedAtUtc),
          stateVersion: Value(run.stateVersion),
          lastEventId: Value(run.lastEventId),
          routineSnapshotJson: Value(SnapshotSerializer.routineToJson(run.routineSnapshot)),
        );

        await dao.upsertRun(runCompanion);

        if (events.isNotEmpty) {
          final eventCompanions = events.map((e) {
            return TimerEventsCompanion(
              eventId: Value(e.eventId),
              runId: Value(e.runId),
              eventType: Value(e.type.name),
              occurredAtUtc: Value(e.occurredAtUtc),
              durationMs: Value(e.durationMs),
              metadataJson: Value(SnapshotSerializer.metadataToJson(e.metadata)),
            );
          }).toList(growable: false);

          await dao.insertEvents(eventCompanions);
        }
      });
    } catch (e) {
      throw PersistenceException('Failed to persist run and events: $e');
    }
  }

  @override
  Future<TimerRun?> getLatestActiveRun() async {
    try {
      final runData = await dao.getLatestActiveRun();
      if (runData == null) return null;

      final routine = SnapshotSerializer.routineFromJson(runData.routineSnapshotJson);

      final status = RunStatus.values.firstWhere(
        (s) => s.name == runData.status,
        orElse: () => RunStatus.idle,
      );

      final phaseStatus = PhaseStatus.values.firstWhere(
        (p) => p.name == runData.phaseStatus,
        orElse: () => PhaseStatus.active,
      );

      return TimerRun(
        runId: runData.runId,
        routineSnapshot: routine,
        status: status,
        phaseStatus: phaseStatus,
        currentPhaseIndex: runData.currentPhaseIndex,
        repeatIndex: runData.repeatIndex,
        accumulatedMs: runData.accumulatedMs,
        phaseStartedAtUtc: runData.phaseStartedAtUtc,
        phaseStartedMonotonicMs: null, // Reset across process boundaries
        pausedAtUtc: runData.pausedAtUtc,
        stateVersion: runData.stateVersion,
        lastEventId: runData.lastEventId,
      );
    } catch (e) {
      throw PersistenceException('Failed to retrieve latest active run: $e');
    }
  }
}
