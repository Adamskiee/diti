import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/routines/data/starter_routines.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../helpers/test_fakes.dart';

void main() {
  group('starterRoutines presets', () {
    test('contains exactly 3 starter routines', () {
      expect(starterRoutines.length, 3);
    });

    test('all starter presets are valid according to routine validation rules', () {
      for (final routine in starterRoutines) {
        expect(routine.validate(), isNull, reason: '${routine.name} should be valid');
        expect(routine.phases, isNotEmpty);
        for (final phase in routine.phases) {
          expect(phase.isValid, isTrue, reason: 'Phase ${phase.name} in ${routine.name} should be valid');
        }
      }
    });

    test('defines Pomodoro, Deep Work, and Open Flow with expected configurations', () {
      final pomodoro = starterRoutines.firstWhere((r) => r.id == 'pomodoro-default');
      expect(pomodoro.name, 'Classic Pomodoro');
      expect(pomodoro.repeatRule.mode, RepeatMode.count);
      expect(pomodoro.repeatRule.count, 4);
      expect(pomodoro.phases.length, 2);
      expect(pomodoro.phases[0].name, 'Focus');
      expect(pomodoro.phases[0].durationMs, 1500000); // 25 min
      expect(pomodoro.phases[0].transition, TransitionPolicy.auto);
      expect(pomodoro.phases[1].name, 'Short Break');
      expect(pomodoro.phases[1].durationMs, 300000); // 5 min
      expect(pomodoro.phases[1].transition, TransitionPolicy.auto);

      final deepWork = starterRoutines.firstWhere((r) => r.id == 'deep-work-default');
      expect(deepWork.name, 'Deep Work');
      expect(deepWork.repeatRule.mode, RepeatMode.count);
      expect(deepWork.repeatRule.count, 1);
      expect(deepWork.phases.length, 2);
      expect(deepWork.phases[0].name, 'Deep Focus');
      expect(deepWork.phases[0].durationMs, 3000000); // 50 min
      expect(deepWork.phases[0].transition, TransitionPolicy.auto);
      expect(deepWork.phases[1].name, 'Rest & Stretch');
      expect(deepWork.phases[1].durationMs, 600000); // 10 min
      expect(deepWork.phases[1].transition, TransitionPolicy.manual);

      final openFlow = starterRoutines.firstWhere((r) => r.id == 'open-flow-default');
      expect(openFlow.name, 'Open Flow');
      expect(openFlow.repeatRule.mode, RepeatMode.count);
      expect(openFlow.repeatRule.count, 1);
      expect(openFlow.phases.length, 2);
      expect(openFlow.phases[0].name, 'Flow Session');
      expect(openFlow.phases[0].durationMs, isNull); // open-ended
      expect(openFlow.phases[0].transition, TransitionPolicy.manual);
      expect(openFlow.phases[1].name, 'Cooldown');
      expect(openFlow.phases[1].durationMs, 300000); // 5 min
      expect(openFlow.phases[1].transition, TransitionPolicy.manual);
    });

    test('the starter routines tag their phases', () {
      final pomodoro = starterRoutines.firstWhere((r) => r.id == 'pomodoro-default');
      expect(pomodoro.phases[0].kind, PhaseKind.focus);
      expect(pomodoro.phases[1].kind, PhaseKind.rest);

      final deepWork = starterRoutines.firstWhere((r) => r.id == 'deep-work-default');
      expect(deepWork.phases[0].kind, PhaseKind.focus);
      expect(deepWork.phases[1].kind, PhaseKind.rest);

      final openFlow = starterRoutines.firstWhere((r) => r.id == 'open-flow-default');
      expect(openFlow.phases[0].kind, PhaseKind.focus);
      expect(openFlow.phases[1].kind, PhaseKind.rest);
    });
  });

  group('seedStarterRoutines', () {
    test('seedStarterRoutines populates 3 routines when empty', () async {
      final db = createInMemoryTestDatabase();
      final repo = DriftRoutineRepository(db);

      expect(await repo.getAllRoutines(), isEmpty);

      final seeded = await seedStarterRoutines(repo);
      expect(seeded, isTrue);

      final routines = await repo.getAllRoutines();
      expect(routines.length, 3);
      expect(routines.any((r) => r.name.contains('Pomodoro')), isTrue);
      expect(routines.any((r) => r.name.contains('Deep Work')), isTrue);
      expect(routines.any((r) => r.name.contains('Open Flow')), isTrue);

      // Second call is idempotent and does not duplicate
      final seededAgain = await seedStarterRoutines(repo);
      expect(seededAgain, isFalse);
      expect((await repo.getAllRoutines()).length, 3);

      await db.close();
    });

    test('seedStarterRoutines returns false and preserves existing routines if DB is not empty', () async {
      final db = createInMemoryTestDatabase();
      final repo = DriftRoutineRepository(db);

      const customRoutine = Routine(
        id: 'custom-routine-1',
        name: 'Custom User Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'custom-p1',
            name: 'Custom Phase',
            durationMs: 60000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      await repo.saveRoutine(customRoutine);
      expect((await repo.getAllRoutines()).length, 1);

      final seeded = await seedStarterRoutines(repo);
      expect(seeded, isFalse);

      final routines = await repo.getAllRoutines();
      expect(routines.length, 1);
      expect(routines.first.id, 'custom-routine-1');

      await db.close();
    });
  });
}
