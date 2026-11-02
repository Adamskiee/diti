import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../database/tables/plan_blocks_table.dart';

part 'plan_blocks_dao.g.dart';

@DriftAccessor(tables: [PlanBlocks])
class PlanBlocksDao extends DatabaseAccessor<DitiDatabase>
    with _$PlanBlocksDaoMixin {
  PlanBlocksDao(super.db);

  Future<void> insertPlanBlock(PlanBlocksCompanion block) {
    return into(planBlocks).insertOnConflictUpdate(block);
  }

  Future<bool> updatePlanBlock(PlanBlocksCompanion block) {
    return update(planBlocks).replace(block);
  }

  Future<int> deletePlanBlock(String id) {
    return (delete(planBlocks)..where((b) => b.id.equals(id))).go();
  }

  Future<List<PlanBlockData>> getPlanBlocksForDate(String planDate) {
    return (select(planBlocks)
          ..where((b) => b.planDate.equals(planDate))
          ..orderBy([(b) => OrderingTerm.asc(b.scheduledStartUtc)]))
        .get();
  }

  Future<PlanBlockData?> getPlanBlockById(String id) {
    return (select(planBlocks)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> linkSession({
    required String blockId,
    required String sessionId,
    required int actualDurationMs,
    required String status,
  }) {
    return (update(planBlocks)..where((b) => b.id.equals(blockId))).write(
      PlanBlocksCompanion(
        sessionId: Value(sessionId),
        actualDurationMs: Value(actualDurationMs),
        status: Value(status),
      ),
    );
  }
}
