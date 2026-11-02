import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/repeat_rule.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';
import 'package:timer_engine/src/domain/routine.dart';

void main() {
  group('Routine Validation', () {
    test('valid routine passes validation', () {
      final routine = Routine(
        id: 'study-001',
        name: 'Study Session',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'study',
            name: 'Study',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'break',
            name: 'Short Break',
            durationMs: 300000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      expect(routine.validate(), isNull);
    });

    test('routine with empty phases fails validation', () {
      final routine = Routine(
        id: 'empty-001',
        name: 'Empty Routine',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [],
      );

      expect(routine.validate(), equals(TimerError.invalidConfiguration));
    });

    test('routine with empty or blank id/name fails validation', () {
      final blankId = Routine(
        id: '   ',
        name: 'Valid Name',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'p1',
            name: 'Phase 1',
            durationMs: 1000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(blankId.validate(), equals(TimerError.invalidConfiguration));

      final blankName = Routine(
        id: 'valid-id',
        name: '',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'p1',
            name: 'Phase 1',
            durationMs: 1000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(blankName.validate(), equals(TimerError.invalidConfiguration));
    });

    test('routine with duplicate phase IDs fails validation', () {
      final routine = Routine(
        id: 'dup-001',
        name: 'Duplicate Phases',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'phase-1',
            name: 'Phase 1',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'phase-1',
            name: 'Phase 2',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      expect(routine.validate(), equals(TimerError.invalidConfiguration));
    });

    test('open-ended phase with auto transition fails validation', () {
      final routine = Routine(
        id: 'open-auto',
        name: 'Invalid Open Ended',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'flow',
            name: 'Flow',
            durationMs: null,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      expect(routine.validate(), equals(TimerError.invalidConfiguration));
    });

    test('open-ended phase with manual transition passes validation', () {
      final routine = Routine(
        id: 'open-manual',
        name: 'Valid Open Ended',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'flow',
            name: 'Flow',
            durationMs: null,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      expect(routine.validate(), isNull);
    });

    test('phase with non-positive duration fails validation', () {
      final zeroDuration = Routine(
        id: 'zero-dur',
        name: 'Zero Duration',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'p1',
            name: 'Phase 1',
            durationMs: 0,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(zeroDuration.validate(), equals(TimerError.invalidConfiguration));

      final negativeDuration = Routine(
        id: 'neg-dur',
        name: 'Negative Duration',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'p1',
            name: 'Phase 1',
            durationMs: -100,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(
          negativeDuration.validate(), equals(TimerError.invalidConfiguration));
    });

    test('phase with blank id or name fails validation', () {
      final blankPhaseId = Routine(
        id: 'r1',
        name: 'Routine',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: '  ',
            name: 'Phase 1',
            durationMs: 1000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(blankPhaseId.validate(), equals(TimerError.invalidConfiguration));

      final blankPhaseName = Routine(
        id: 'r1',
        name: 'Routine',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'p1',
            name: '  ',
            durationMs: 1000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(
          blankPhaseName.validate(), equals(TimerError.invalidConfiguration));
    });

    test('repeat count must be at least 1 when mode is count', () {
      final zeroCount = Routine(
        id: 'bad-count-0',
        name: 'Bad Repeat Count',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 0),
        phases: const [
          RoutinePhase(
            id: 'phase-1',
            name: 'Phase 1',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(zeroCount.validate(), equals(TimerError.invalidConfiguration));

      final negativeCount = Routine(
        id: 'bad-count-neg',
        name: 'Bad Repeat Count',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: -1),
        phases: const [
          RoutinePhase(
            id: 'phase-1',
            name: 'Phase 1',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      expect(negativeCount.validate(), equals(TimerError.invalidConfiguration));
    });

    test('repeat mode forever is valid regardless of count', () {
      final routine = Routine(
        id: 'forever-001',
        name: 'Forever Routine',
        repeatRule: const RepeatRule(mode: RepeatMode.forever, count: 0),
        phases: const [
          RoutinePhase(
            id: 'phase-1',
            name: 'Phase 1',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      expect(routine.validate(), isNull);
    });
  });

  group(
      'Domain Entities: RepeatRule, RoutinePhase, Routine properties & methods',
      () {
    test('RepeatRule equality and hashCode', () {
      const r1 = RepeatRule(mode: RepeatMode.count, count: 3);
      const r2 = RepeatRule(mode: RepeatMode.count, count: 3);
      const r3 = RepeatRule(mode: RepeatMode.forever);

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('RoutinePhase properties, copyWith, equality, hashCode', () {
      const p1 = RoutinePhase(
        id: 'p1',
        name: 'Phase 1',
        durationMs: 60000,
        transition: TransitionPolicy.auto,
      );
      expect(p1.isOpenEnded, isFalse);
      expect(p1.isValid, isTrue);

      const pOpen = RoutinePhase(
        id: 'p-open',
        name: 'Open',
        durationMs: null,
        transition: TransitionPolicy.manual,
      );
      expect(pOpen.isOpenEnded, isTrue);
      expect(pOpen.isValid, isTrue);

      final pCopied = p1.copyWith(name: 'Updated Phase', durationMs: 90000);
      expect(pCopied.id, equals('p1'));
      expect(pCopied.name, equals('Updated Phase'));
      expect(pCopied.durationMs, equals(90000));
      expect(pCopied.transition, equals(TransitionPolicy.auto));

      const pIdentical = RoutinePhase(
        id: 'p1',
        name: 'Phase 1',
        durationMs: 60000,
        transition: TransitionPolicy.auto,
      );
      expect(p1, equals(pIdentical));
      expect(p1.hashCode, equals(pIdentical.hashCode));
    });

    test('Routine clone and equality', () {
      final original = Routine(
        id: 'study-001',
        name: 'Study Session',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
        phases: const [
          RoutinePhase(
            id: 'study',
            name: 'Study',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'break',
            name: 'Short Break',
            durationMs: 300000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      final cloned = original.clone();
      expect(cloned, equals(original));
      expect(cloned.hashCode, equals(original.hashCode));
      expect(identical(cloned, original), isFalse);
      expect(identical(cloned.phases, original.phases), isFalse);

      final different = Routine(
        id: 'study-002',
        name: 'Study Session',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
        phases: original.phases,
      );
      expect(original, isNot(equals(different)));

      final copiedRoutine = original.copyWith(name: 'Updated Name');
      expect(copiedRoutine.id, equals(original.id));
      expect(copiedRoutine.name, equals('Updated Name'));
      expect(copiedRoutine.repeatRule, equals(original.repeatRule));
      expect(copiedRoutine.phases, equals(original.phases));
    });

    test('RepeatRule copyWith works as expected', () {
      const r = RepeatRule(mode: RepeatMode.count, count: 2);
      final updated = r.copyWith(count: 5);
      expect(updated.mode, equals(RepeatMode.count));
      expect(updated.count, equals(5));

      final updatedMode = r.copyWith(mode: RepeatMode.forever);
      expect(updatedMode.mode, equals(RepeatMode.forever));
      expect(updatedMode.count, equals(2));
    });
  });
}
