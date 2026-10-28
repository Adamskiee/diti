import 'package:diti_database/src/domain/session_record.dart';

abstract interface class SessionRepository {
  Future<void> recordSession(SessionRecord session);
  Future<void> saveSession(SessionRecord session);
  Future<SessionRecord?> getSession(String sessionId);
  Future<SessionRecord?> getSessionById(String sessionId);
  Future<List<SessionRecord>> getSessionsInRange(DateTime startUtc, DateTime endUtc);
  Future<List<SessionRecord>> getSessionsForPlanBlock(String planBlockId);
  Future<void> deleteSession(String sessionId);
}
