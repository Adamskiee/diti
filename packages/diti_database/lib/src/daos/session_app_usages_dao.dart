import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../database/tables/session_app_usages_table.dart';

part 'session_app_usages_dao.g.dart';

@DriftAccessor(tables: [SessionAppUsages])
class SessionAppUsagesDao extends DatabaseAccessor<DitiDatabase>
    with _$SessionAppUsagesDaoMixin {
  SessionAppUsagesDao(super.db);

  Future<void> insertUsages(List<SessionAppUsagesCompanion> usages) async {
    await batch((batch) {
      batch.insertAll(sessionAppUsages, usages, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<SessionAppUsage>> getUsagesForSession(String sessionId) {
    return (select(sessionAppUsages)..where((t) => t.sessionId.equals(sessionId)))
        .get();
  }

  Future<int> deleteUsagesForSession(String sessionId) {
    return (delete(sessionAppUsages)..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }
}
