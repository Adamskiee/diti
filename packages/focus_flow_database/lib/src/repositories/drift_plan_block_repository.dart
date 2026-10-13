import 'package:drift/drift.dart';
import 'package:focus_flow_database/src/database/focus_flow_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent, PlanBlock;
import 'package:focus_flow_database/src/daos/plan_blocks_dao.dart';
import 'package:focus_flow_database/src/domain/plan_block.dart';
import 'package:focus_flow_database/src/repositories/plan_block_repository.dart';

class DriftPlanBlockRepository implements PlanBlockRepository {
  final FocusFlowDatabase database;
  final PlanBlocksDao dao;

  DriftPlanBlockRepository(this.database) : dao = PlanBlocksDao(database);

  @override
  Future<void> createPlanBlock(PlanBlock block) async {
    await dao.insertPlanBlock(_toCompanion(block));
  }

  @override
  Future<void> updatePlanBlock(PlanBlock block) async {
    await dao.updatePlanBlock(_toCompanion(block));
  }

  @override
  Future<void> deletePlanBlock(String id) async {
    await dao.deletePlanBlock(id);
  }

  @override
  Future<List<PlanBlock>> getBlocksForDate(String planDate) async {
    final rows = await dao.getPlanBlocksForDate(planDate);
    return rows.map(_mapToDomain).toList(growable: false);
  }

  @override
  Future<PlanBlock?> getBlockById(String id) async {
    final row = await dao.getPlanBlockById(id);
    return row == null ? null : _mapToDomain(row);
  }

  @override
  Future<void> linkSession({
    required String blockId,
    required String sessionId,
    required int actualDurationMs,
    required PlanBlockStatus status,
  }) async {
    await dao.linkSession(
      blockId: blockId,
      sessionId: sessionId,
      actualDurationMs: actualDurationMs,
      status: status.name,
    );
  }

  PlanBlock _mapToDomain(PlanBlockData row) {
    final status = PlanBlockStatus.values.firstWhere(
      (s) => s.name == row.status,
      orElse: () => PlanBlockStatus.scheduled,
    );

    return PlanBlock(
      id: row.id,
      planDate: row.planDate,
      scheduledStartUtc: row.scheduledStartUtc,
      timezoneId: row.timezoneId,
      plannedDurationMs: row.plannedDurationMs,
      routineId: row.routineId,
      actualDurationMs: row.actualDurationMs,
      sessionId: row.sessionId,
      status: status,
    );
  }

  PlanBlocksCompanion _toCompanion(PlanBlock block) {
    return PlanBlocksCompanion(
      id: Value(block.id),
      planDate: Value(block.planDate),
      scheduledStartUtc: Value(
        block.scheduledStartUtc.isUtc
            ? block.scheduledStartUtc
            : block.scheduledStartUtc.toUtc(),
      ),
      timezoneId: Value(block.timezoneId),
      plannedDurationMs: Value(block.plannedDurationMs),
      routineId: Value(block.routineId),
      actualDurationMs: Value(block.actualDurationMs),
      sessionId: Value(block.sessionId),
      status: Value(block.status.name),
    );
  }
}
