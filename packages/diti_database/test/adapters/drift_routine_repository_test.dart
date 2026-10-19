import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/src/database/diti_database.dart'
    hide Routine, RoutinePhase;
import 'package:diti_database/src/repositories/drift_routine_repository.dart';

void main() {
  late DitiDatabase db;
  late DriftRoutineRepository repository;

  setUp(() {
    db = DitiDatabase.inMemory();
    repository = DriftRoutineRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftRoutineRepository', () {
    test('implements RoutineRepository contract and saves/retrieves domain Routine', () async {
      final routine = Routine(
        id: 'routine-study',
        name: 'Study Session',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 3),
        phases: const [
          RoutinePhase(
            id: 'study-1',
            name: 'Study Subject A',
            durationMs: 1800000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'study-break',
            name: 'Rest',
            durationMs: 300000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      await repository.saveRoutine(routine);

      final fetched = await repository.getRoutine('routine-study');
      expect(fetched, isNotNull);
      expect(fetched!.id, equals(routine.id));
      expect(fetched.name, equals(routine.name));
      expect(fetched.repeatRule.mode, equals(RepeatMode.count));
      expect(fetched.repeatRule.count, equals(3));
      expect(fetched.phases.length, equals(2));
      expect(fetched.phases[0].id, equals('study-1'));
      expect(fetched.phases[1].transition, equals(TransitionPolicy.manual));
      expect(fetched, equals(routine));
    });

    test('saves and retrieves Routine with forever repeatMode', () async {
      const routineForever = Routine(
        id: 'routine-infinite',
        name: 'Infinite Loop',
        repeatRule: RepeatRule(mode: RepeatMode.forever),
        phases: [
          RoutinePhase(
            id: 'phase-inf',
            name: 'Continuous Work',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      await repository.saveRoutine(routineForever);

      final fetched = await repository.getRoutine('routine-infinite');
      expect(fetched, isNotNull);
      expect(fetched!.repeatRule.mode, equals(RepeatMode.forever));
      expect(fetched.repeatRule.count, equals(1));
      expect(fetched, equals(routineForever));
    });

    test('returns null when routine is not found', () async {
      final fetched = await repository.getRoutine('unknown-id');
      expect(fetched, isNull);
    });

    test('getAllRoutines returns list of mapped domain routines', () async {
      const routine1 = Routine(
        id: 'r1',
        name: 'R1',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'P1', durationMs: 1000, transition: TransitionPolicy.auto),
        ],
      );
      await repository.saveRoutine(routine1);

      final list = await repository.getAllRoutines();
      expect(list.length, equals(1));
      expect(list.first.id, equals('r1'));
    });

    test('deleteRoutine removes routine and associated phases', () async {
      const routine = Routine(
        id: 'r-delete',
        name: 'To Delete',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p-del', name: 'Phase Del', durationMs: 5000, transition: TransitionPolicy.auto),
        ],
      );
      await repository.saveRoutine(routine);

      final before = await repository.getRoutine('r-delete');
      expect(before, isNotNull);

      await repository.deleteRoutine('r-delete');

      final after = await repository.getRoutine('r-delete');
      expect(after, isNull);

      final all = await repository.getAllRoutines();
      expect(all, isEmpty);
    });
  });
}
