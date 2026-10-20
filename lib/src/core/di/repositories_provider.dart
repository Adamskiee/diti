import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'database_provider.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftRoutineRepository(db);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftSessionRepository(db);
});

final planBlockRepositoryProvider = Provider<PlanBlockRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftPlanBlockRepository(db);
});
