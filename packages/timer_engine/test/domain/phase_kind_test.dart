import 'package:test/test.dart';
import 'package:timer_engine/src/domain/enums.dart';
import 'package:timer_engine/src/domain/routine_phase.dart';

void main() {
  group('PhaseKind.inferFromName', () {
    test('classifies rest-sounding names as rest', () {
      expect(PhaseKind.inferFromName('Short Break'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('Rest & Stretch'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('Cooldown'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('Coffee Break'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('Lunch'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('Recovery'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('Power Nap Pause'), PhaseKind.rest);
    });

    test('matches case-insensitively', () {
      expect(PhaseKind.inferFromName('REST'), PhaseKind.rest);
      expect(PhaseKind.inferFromName('break'), PhaseKind.rest);
    });

    test('classifies everything else as focus', () {
      expect(PhaseKind.inferFromName('Focus'), PhaseKind.focus);
      expect(PhaseKind.inferFromName('Deep Focus'), PhaseKind.focus);
      expect(PhaseKind.inferFromName('Reading'), PhaseKind.focus);
      expect(PhaseKind.inferFromName(''), PhaseKind.focus);
    });
  });

  group('RoutinePhase.kind', () {
    test('defaults to focus', () {
      const phase = RoutinePhase(
        id: 'p1',
        name: 'Focus',
        transition: TransitionPolicy.auto,
      );
      expect(phase.kind, PhaseKind.focus);
    });

    test('copyWith preserves kind and can override it', () {
      const phase = RoutinePhase(
        id: 'p1',
        name: 'Focus',
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      );
      expect(phase.copyWith().kind, PhaseKind.rest);
      expect(phase.copyWith(name: 'Renamed').kind, PhaseKind.rest);
      expect(phase.copyWith(kind: PhaseKind.focus).kind, PhaseKind.focus);
    });

    test('equality distinguishes differing kinds', () {
      const a = RoutinePhase(
          id: 'p1', name: 'Focus', transition: TransitionPolicy.auto);
      const b = RoutinePhase(
          id: 'p1',
          name: 'Focus',
          transition: TransitionPolicy.auto,
          kind: PhaseKind.rest);
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}