import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/repositories_provider.dart';

class RoutineListController extends AsyncNotifier<List<Routine>> {
  @override
  FutureOr<List<Routine>> build() async {
    final repo = ref.watch(routineRepositoryProvider);
    final list = await repo.getAllRoutines();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(routineRepositoryProvider);
      final list = await repo.getAllRoutines();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<void> duplicateRoutine(Routine routine) async {
    try {
      final repo = ref.read(routineRepositoryProvider);
      const uuid = Uuid();
      final clonedPhases = routine.phases.map((p) {
        return RoutinePhase(
          id: uuid.v4(),
          name: p.name,
          durationMs: p.durationMs,
          transition: p.transition,
          // The copy is a new routine, but its phases keep the kinds they
          // were tagged with: a duplicated break is still a break.
          kind: p.kind,
        );
      }).toList();

      final duplicated = Routine(
        id: uuid.v4(),
        name: '${routine.name} (Copy)',
        repeatRule: routine.repeatRule,
        phases: clonedPhases,
      );

      await repo.saveRoutine(duplicated);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      final repo = ref.read(routineRepositoryProvider);
      await repo.deleteRoutine(id);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
