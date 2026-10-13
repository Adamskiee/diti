import 'package:timer_engine/src/domain/routine.dart';
import 'package:timer_engine/src/ports/routine_repository.dart';

class InMemoryRoutineRepository implements RoutineRepository {
  final Map<String, Routine> _routines = {};

  Future<void> saveRoutine(Routine routine) async {
    _routines[routine.id] = routine;
  }

  @override
  Future<Routine?> getRoutine(String routineId) async {
    return _routines[routineId];
  }
}
