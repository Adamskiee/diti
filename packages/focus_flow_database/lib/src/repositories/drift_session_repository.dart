import 'package:drift/drift.dart';
import 'package:focus_flow_database/src/database/focus_flow_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent;
import 'package:focus_flow_database/src/daos/sessions_dao.dart';
import 'package:focus_flow_database/src/domain/session_record.dart';
import 'package:focus_flow_database/src/mappers/snapshot_serializer.dart';
import 'package:focus_flow_database/src/repositories/session_repository.dart';

class DriftSessionRepository implements SessionRepository {
  final FocusFlowDatabase database;
  final SessionsDao dao;

  DriftSessionRepository(this.database) : dao = SessionsDao(database);

  @override
  Future<void> recordSession(SessionRecord session) async {
    final sessionCompanion = SessionsCompanion(
      sessionId: Value(session.sessionId),
      routineId: Value(session.routineId),
      planBlockId: Value(session.planBlockId),
      routineName: Value(session.routineName),
      startedAtUtc: Value(session.startedAtUtc),
      endedAtUtc: Value(session.endedAtUtc),
      totalDurationMs: Value(session.totalDurationMs),
      outcome: Value(session.outcome.name),
      routineSnapshotJson: Value(SnapshotSerializer.routineToJson(session.routineSnapshot)),
    );

    final eventCompanions = session.events.map((e) {
      return SessionEventsCompanion(
        eventId: Value(e.eventId),
        sessionId: Value(e.sessionId),
        eventType: Value(e.eventType),
        occurredAtUtc: Value(e.occurredAtUtc),
        phaseId: Value(e.phaseId),
        phaseName: Value(e.phaseName),
        durationMs: Value(e.durationMs),
        outcome: Value(e.outcome),
      );
    }).toList(growable: false);

    await dao.createSessionWithEvents(sessionCompanion, eventCompanions);
  }

  @override
  Future<SessionRecord?> getSession(String sessionId) async {
    final row = await dao.getSessionById(sessionId);
    if (row == null) return null;
    return _mapSession(row);
  }

  Future<SessionRecord> _mapSession(SessionData row) async {
    final eventRows = await dao.getEventsForSession(row.sessionId);
    final events = eventRows.map((e) {
      return SessionEventRecord(
        eventId: e.eventId,
        sessionId: e.sessionId,
        eventType: e.eventType,
        occurredAtUtc: e.occurredAtUtc,
        phaseId: e.phaseId,
        phaseName: e.phaseName,
        durationMs: e.durationMs,
        outcome: e.outcome,
      );
    }).toList(growable: false);

    final outcome = SessionOutcome.values.firstWhere(
      (o) => o.name == row.outcome,
      orElse: () => SessionOutcome.completed,
    );

    final routineSnapshot = SnapshotSerializer.routineFromJson(row.routineSnapshotJson);

    return SessionRecord(
      sessionId: row.sessionId,
      routineId: row.routineId,
      planBlockId: row.planBlockId,
      routineName: row.routineName,
      startedAtUtc: row.startedAtUtc,
      endedAtUtc: row.endedAtUtc,
      totalDurationMs: row.totalDurationMs,
      outcome: outcome,
      routineSnapshot: routineSnapshot,
      events: events,
    );
  }

  @override
  Future<List<SessionRecord>> getSessionsInRange(DateTime startUtc, DateTime endUtc) async {
    final start = startUtc.isUtc ? startUtc : startUtc.toUtc();
    final end = endUtc.isUtc ? endUtc : endUtc.toUtc();
    final rows = await dao.getSessionsInRange(startUtc: start, endUtc: end);
    final results = <SessionRecord>[];
    for (final r in rows) {
      results.add(await _mapSession(r));
    }
    return results;
  }

  @override
  Future<List<SessionRecord>> getSessionsForPlanBlock(String planBlockId) async {
    final rows = await dao.getSessionsForPlanBlock(planBlockId);
    final results = <SessionRecord>[];
    for (final r in rows) {
      results.add(await _mapSession(r));
    }
    return results;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await dao.deleteSession(sessionId);
  }
}
