import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../database/tables/sessions_table.dart';
import '../database/tables/session_events_table.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions, SessionEvents])
class SessionsDao extends DatabaseAccessor<DitiDatabase> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Future<void> createSessionWithEvents(
    SessionsCompanion session,
    List<SessionEventsCompanion> events,
  ) {
    return transaction(() async {
      await into(sessions).insertOnConflictUpdate(session);
      for (final event in events) {
        await into(sessionEvents).insertOnConflictUpdate(event);
      }
    });
  }

  Future<SessionData?> getSessionById(String sessionId) {
    return (select(sessions)..where((s) => s.sessionId.equals(sessionId))).getSingleOrNull();
  }

  Future<List<SessionEventData>> getEventsForSession(String sessionId) {
    return (select(sessionEvents)
          ..where((e) => e.sessionId.equals(sessionId))
          ..orderBy([(e) => OrderingTerm.asc(e.occurredAtUtc)]))
        .get();
  }

  Future<List<SessionData>> getSessionsInRange({
    required DateTime startUtc,
    required DateTime endUtc,
  }) {
    return (select(sessions)
          ..where((s) => s.startedAtUtc.isBiggerOrEqualValue(startUtc) & s.startedAtUtc.isSmallerOrEqualValue(endUtc))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAtUtc)]))
        .get();
  }

  Future<List<SessionData>> getSessionsForPlanBlock(String planBlockId) {
    return (select(sessions)
          ..where((s) => s.planBlockId.equals(planBlockId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAtUtc)]))
        .get();
  }

  Future<int> deleteSession(String sessionId) {
    return (delete(sessions)..where((s) => s.sessionId.equals(sessionId))).go();
  }
}
