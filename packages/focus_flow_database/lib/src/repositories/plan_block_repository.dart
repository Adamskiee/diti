import 'package:focus_flow_database/src/domain/plan_block.dart';

abstract interface class PlanBlockRepository {
  Future<void> createPlanBlock(PlanBlock block);
  Future<void> updatePlanBlock(PlanBlock block);
  Future<void> deletePlanBlock(String id);
  Future<List<PlanBlock>> getBlocksForDate(String planDate);
  Future<PlanBlock?> getBlockById(String id);
  Future<void> linkSession({
    required String blockId,
    required String sessionId,
    required int actualDurationMs,
    required PlanBlockStatus status,
  });
}
