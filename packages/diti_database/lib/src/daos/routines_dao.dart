import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../database/tables/routines_table.dart';
import '../database/tables/routine_phases_table.dart';

part 'routines_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutinePhases])
class RoutinesDao extends DatabaseAccessor<DitiDatabase> with _$RoutinesDaoMixin {
  RoutinesDao(super.db);

  Future<void> upsertRoutineWithPhases(
    RoutinesCompanion routine,
    List<RoutinePhasesCompanion> phases,
  ) {
    return transaction(() async {
      await into(routines).insertOnConflictUpdate(routine);
      await (delete(routinePhases)..where((p) => p.routineId.equals(routine.id.value))).go();
      for (final phase in phases) {
        await into(routinePhases).insert(phase);
      }
    });
  }

  Future<RoutineData?> getRoutineById(String id) {
    return (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  Future<List<RoutinePhaseData>> getPhasesForRoutine(String routineId) {
    return (select(routinePhases)
          ..where((p) => p.routineId.equals(routineId))
          ..orderBy([(p) => OrderingTerm.asc(p.orderIndex)]))
        .get();
  }

  Future<List<RoutineData>> getAllRoutines() {
    return (select(routines)..orderBy([(r) => OrderingTerm.asc(r.name)])).get();
  }

  Future<int> deleteRoutine(String id) {
    return (delete(routines)..where((r) => r.id.equals(id))).go();
  }
}
