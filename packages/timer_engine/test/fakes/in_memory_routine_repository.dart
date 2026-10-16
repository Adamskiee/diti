import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/ports/routine_repository.dart';

class InMemoryRoutineRepository implements RoutineRepository {
  final Map<String, Routine> _routines = {};

  @override
  Future<void> saveRoutine(Routine routine) async {
    _routines[routine.id] = routine;
  }

  @override
  Future<Routine?> getRoutine(String routineId) async {
    return _routines[routineId];
  }

  @override
  Future<List<Routine>> getAllRoutines() async {
    return _routines.values.toList();
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    _routines.remove(routineId);
  }
}

