import '../domain/routine.dart';

abstract interface class RoutineRepository {
  Future<Routine?> getRoutine(String routineId);
  Future<List<Routine>> getAllRoutines();
  Future<void> saveRoutine(Routine routine);
  Future<void> deleteRoutine(String routineId);
}
