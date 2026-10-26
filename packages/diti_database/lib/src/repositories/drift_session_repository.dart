import 'package:drift/drift.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/src/database/diti_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent;
import 'package:diti_database/src/daos/sessions_dao.dart';
import 'package:diti_database/src/daos/session_app_usages_dao.dart';
import 'package:diti_database/src/domain/session_record.dart';
import 'package:diti_database/src/domain/session_app_usage_record.dart';
import 'package:diti_database/src/domain/session_validator.dart';
import 'package:diti_database/src/mappers/snapshot_serializer.dart';
import 'package:diti_database/src/repositories/session_repository.dart';

class DriftSessionRepository implements SessionRepository {
  final DitiDatabase database;
  final SessionsDao dao;
  final SessionAppUsagesDao appUsagesDao;

  DriftSessionRepository(this.database)
      : dao = SessionsDao(database),
        appUsagesDao = SessionAppUsagesDao(database);

  @override
  Future<void> recordSession(SessionRecord session) async {
    final validation = SessionValidator.validate(session);
    if (!validation.isValid) {
      throw SessionValidationException(
        'Cannot persist invalid session: ${validation.errors.map((e) => "${e.field}: ${e.message}").join(", ")}',
        validation.errors,
      );
    }

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
        kind: Value(e.kind.name),
      );
    }).toList(growable: false);

    await dao.createSessionWithEvents(sessionCompanion, eventCompanions);

    if (session.appUsages.isNotEmpty) {
      final usageCompanions = session.appUsages.map((u) {
        return SessionAppUsagesCompanion(
          id: Value(u.id),
          sessionId: Value(u.sessionId),
          appName: Value(u.appName),
          category: Value(u.category),
          sampleTitle: Value(u.sampleTitle),
          durationMs: Value(u.durationMs),
        );
      }).toList(growable: false);
      await appUsagesDao.insertUsages(usageCompanions);
    }
  }

  @override
  Future<void> saveSession(SessionRecord session) => recordSession(session);

  @override
  Future<SessionRecord?> getSession(String sessionId) async {
    final row = await dao.getSessionById(sessionId);
    if (row == null) return null;
    return _mapSession(row);
  }

  @override
  Future<SessionRecord?> getSessionById(String sessionId) => getSession(sessionId);

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
        kind: e.kind == PhaseKind.rest.name ? PhaseKind.rest : PhaseKind.focus,
      );
    }).toList(growable: false);

    final usageRows = await appUsagesDao.getUsagesForSession(row.sessionId);
    final appUsages = usageRows.map((u) {
      return SessionAppUsageRecord(
        id: u.id,
        sessionId: u.sessionId,
        appName: u.appName,
        category: u.category,
        sampleTitle: u.sampleTitle,
        durationMs: u.durationMs,
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
      appUsages: appUsages,
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
