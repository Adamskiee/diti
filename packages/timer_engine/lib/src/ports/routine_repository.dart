import '../domain/routine.dart';

abstract interface class RoutineRepository {
  Future<Routine?> getRoutine(String routineId);
}
