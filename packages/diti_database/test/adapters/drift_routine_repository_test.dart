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
    test(
        'implements RoutineRepository contract and saves/retrieves domain Routine',
        () async {
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

    test('a routine round-trips phase kinds', () async {
      final routine = Routine(
        id: 'routine-kinds',
        name: 'Kinds',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'kind-focus',
            name: 'Focus',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
            kind: PhaseKind.focus,
          ),
          RoutinePhase(
            id: 'kind-break',
            name: 'Short Break',
            durationMs: 300000,
            transition: TransitionPolicy.manual,
            kind: PhaseKind.rest,
          ),
        ],
      );

      await repository.saveRoutine(routine);

      final fetched = await repository.getRoutine('routine-kinds');
      expect(fetched, isNotNull);
      expect(fetched!.phases[0].kind, equals(PhaseKind.focus));
      expect(fetched.phases[1].kind, equals(PhaseKind.rest));
    });

    test('saving a routine preserves an inferred kind', () async {
      final routine = Routine(
        id: 'routine-inferred',
        name: 'Inferred',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'phase-break',
            name: 'Short Break',
            durationMs: 300000,
            transition: TransitionPolicy.auto,
            kind: PhaseKind.rest,
          ),
        ],
      );

      await repository.saveRoutine(routine);

      // A user edits the routine: the editor loads it, changes it and saves
      // it again. The dao deletes and re-inserts every phase row, so a save
      // that forgot the kind would reset it to the column default.
      final loaded = await repository.getRoutine('routine-inferred');
      expect(loaded!.phases.single.kind, equals(PhaseKind.rest));

      await repository.saveRoutine(
        Routine(
          id: loaded.id,
          name: 'Inferred and edited',
          repeatRule: loaded.repeatRule,
          phases: loaded.phases,
        ),
      );

      final reloaded = await repository.getRoutine('routine-inferred');
      expect(reloaded, isNotNull);
      expect(reloaded!.phases.single.kind, equals(PhaseKind.rest));
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
          RoutinePhase(
              id: 'p1',
              name: 'P1',
              durationMs: 1000,
              transition: TransitionPolicy.auto),
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
          RoutinePhase(
              id: 'p-del',
              name: 'Phase Del',
              durationMs: 5000,
              transition: TransitionPolicy.auto),
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
