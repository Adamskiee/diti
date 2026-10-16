import 'package:drift/drift.dart';
import 'package:timer_engine/timer_engine.dart';
import '../database/focus_flow_database.dart' hide Routine, RoutinePhase;
import '../daos/routines_dao.dart';

class DriftRoutineRepository implements RoutineRepository {
  final FocusFlowDatabase database;
  final RoutinesDao dao;

  DriftRoutineRepository(this.database) : dao = RoutinesDao(database);

  @override
  Future<Routine?> getRoutine(String routineId) async {
    final routineData = await dao.getRoutineById(routineId);
    if (routineData == null) return null;
    return _mapRoutine(routineData);
  }

  Future<Routine> _mapRoutine(RoutineData routineData) async {
    final phaseRows = await dao.getPhasesForRoutine(routineData.id);
    final phases = phaseRows.map((p) {
      return RoutinePhase(
        id: p.id,
        name: p.name,
        durationMs: p.durationMs,
        transition: p.transitionPolicy == 'manual'
            ? TransitionPolicy.manual
            : TransitionPolicy.auto,
      );
    }).toList(growable: false);

    final repeatMode = routineData.repeatMode == 'forever'
        ? RepeatMode.forever
        : RepeatMode.count;

    return Routine(
      id: routineData.id,
      name: routineData.name,
      repeatRule: RepeatRule(
        mode: repeatMode,
        count: routineData.repeatCount ?? 1,
      ),
      phases: phases,
    );
  }

  @override
  Future<void> saveRoutine(Routine routine) async {
    final now = DateTime.now().toUtc();
    final existing = await dao.getRoutineById(routine.id);
    final createdAt = existing?.createdAtUtc ?? now;
    final routineCompanion = RoutinesCompanion(
      id: Value(routine.id),
      name: Value(routine.name),
      repeatMode: Value(routine.repeatRule.mode.name),
      repeatCount: Value(routine.repeatRule.mode == RepeatMode.count
          ? routine.repeatRule.count
          : null),
      createdAtUtc: Value(createdAt),
      updatedAtUtc: Value(now),
    );

    final phaseCompanions = <RoutinePhasesCompanion>[];
    for (var i = 0; i < routine.phases.length; i++) {
      final p = routine.phases[i];
      phaseCompanions.add(RoutinePhasesCompanion(
        id: Value(p.id),
        routineId: Value(routine.id),
        orderIndex: Value(i),
        name: Value(p.name),
        durationMs: Value(p.durationMs),
        transitionPolicy: Value(p.transition.name),
      ));
    }

    await dao.upsertRoutineWithPhases(routineCompanion, phaseCompanions);
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await dao.deleteRoutine(routineId);
  }

  @override
  Future<List<Routine>> getAllRoutines() async {
    final routineRows = await dao.getAllRoutines();
    final result = <Routine>[];
    for (final row in routineRows) {
      result.add(await _mapRoutine(row));
    }
    return result;
  }
}
