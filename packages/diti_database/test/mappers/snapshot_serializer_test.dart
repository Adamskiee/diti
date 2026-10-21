import 'dart:convert';
import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/diti_database.dart';

void main() {
  group('SnapshotSerializer', () {
    test('serializes and deserializes Routine with count repeat rule', () {
      final original = Routine(
        id: 'routine-001',
        name: 'Deep Work Routine',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 2),
        phases: const [
          RoutinePhase(
            id: 'phase-focus',
            name: 'Focus',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'phase-break',
            name: 'Short Break',
            durationMs: 300000,
            transition: TransitionPolicy.manual,
          ),
          RoutinePhase(
            id: 'phase-open',
            name: 'Open Flow',
            durationMs: null,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      final jsonStr = SnapshotSerializer.routineToJson(original);
      final restored = SnapshotSerializer.routineFromJson(jsonStr);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.repeatRule.mode, equals(RepeatMode.count));
      expect(restored.repeatRule.count, equals(2));
      expect(restored.phases.length, equals(3));
      expect(restored.phases[0].id, equals('phase-focus'));
      expect(restored.phases[0].durationMs, equals(1500000));
      expect(restored.phases[0].transition, equals(TransitionPolicy.auto));
      expect(restored.phases[2].durationMs, isNull);
      expect(restored.phases[2].transition, equals(TransitionPolicy.manual));
      expect(restored, equals(original));
    });

    test('serializes and deserializes Routine with forever repeat rule', () {
      const original = Routine(
        id: 'routine-forever',
        name: 'Continuous Loop',
        repeatRule: RepeatRule(mode: RepeatMode.forever, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      final jsonStr = SnapshotSerializer.routineToJson(original);
      final restored = SnapshotSerializer.routineFromJson(jsonStr);

      expect(restored.repeatRule.mode, equals(RepeatMode.forever));
      expect(restored, equals(original));
    });

    test('serializes and deserializes metadata map', () {
      final meta = {'source': 'manual_skip', 'reason': 'interrupted', 'index': 42};
      final jsonStr = SnapshotSerializer.metadataToJson(meta);
      final restored = SnapshotSerializer.metadataFromJson(jsonStr);

      expect(restored['source'], equals('manual_skip'));
      expect(restored['reason'], equals('interrupted'));
      expect(restored['index'], equals(42));
    });

    test('throws FormatException on invalid json string', () {
      expect(() => SnapshotSerializer.routineFromJson('not-json'), throwsFormatException);
      expect(() => SnapshotSerializer.metadataFromJson('not-json'), throwsFormatException);
    });

    test('throws FormatException when schemaVersion is missing or unsupported', () {
      const missingVersion = '{"id":"r1","name":"Routine"}';
      expect(() => SnapshotSerializer.routineFromJson(missingVersion), throwsFormatException);

      const unsupportedVersion = '{"schemaVersion":3,"id":"r1","name":"Routine"}';
      expect(() => SnapshotSerializer.routineFromJson(unsupportedVersion), throwsFormatException);
    });

    test('writes schemaVersion 2 and preserves phase kinds', () {
      final routine = Routine(
        id: 'r', name: 'R',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(id: 'f', name: 'Focus', durationMs: 1500000,
              transition: TransitionPolicy.auto, kind: PhaseKind.focus),
          RoutinePhase(id: 'b', name: 'Short Break', durationMs: 300000,
              transition: TransitionPolicy.auto, kind: PhaseKind.rest),
        ],
      );
      final json = jsonDecode(SnapshotSerializer.routineToJson(routine));
      expect(json['schemaVersion'], 2);
      expect((json['phases'] as List)[1]['kind'], 'rest');
    });

    test('round-trips phase kinds', () {
      final routine = Routine(
        id: 'r', name: 'R',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(id: 'f', name: 'Focus', durationMs: 1500000,
              transition: TransitionPolicy.auto, kind: PhaseKind.focus),
          RoutinePhase(id: 'b', name: 'Short Break', durationMs: 300000,
              transition: TransitionPolicy.auto, kind: PhaseKind.rest),
        ],
      );
      final jsonStr = SnapshotSerializer.routineToJson(routine);
      final restored = SnapshotSerializer.routineFromJson(jsonStr);
      expect(restored.phases[0].kind, PhaseKind.focus);
      expect(restored.phases[1].kind, PhaseKind.rest);
    });

    test('loads a version 1 snapshot with every phase as focus', () {
      final json = jsonEncode({
        'schemaVersion': 1, 'id': 'r', 'name': 'R',
        'repeatRule': {'mode': 'count', 'count': 1},
        'phases': [
          {'id': 'f', 'name': 'Focus', 'durationMs': 1500000, 'transition': 'auto'},
        ],
      });
      final routine = SnapshotSerializer.routineFromJson(json);
      expect(routine.phases.first.kind, PhaseKind.focus);
    });

    test('rejects an unsupported snapshot version', () {
      const version3 = '{"schemaVersion":3,"id":"r1","name":"Routine"}';
      expect(() => SnapshotSerializer.routineFromJson(version3), throwsFormatException);
    });

    test('a run keeps its own kinds when the live routine changes', () {
      final routine = Routine(
        id: 'r', name: 'R',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(id: 'f', name: 'Focus', durationMs: 1500000,
              transition: TransitionPolicy.auto, kind: PhaseKind.focus),
        ],
      );
      final runJson = SnapshotSerializer.routineToJson(routine);
      final runRoutine = SnapshotSerializer.routineFromJson(runJson);
      expect(runRoutine.phases.first.kind, PhaseKind.focus);

      // Change the live routine's phase kind to rest
      final updatedRoutine = Routine(
        id: 'r', name: 'R',
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(id: 'f', name: 'Focus', durationMs: 1500000,
              transition: TransitionPolicy.auto, kind: PhaseKind.rest),
        ],
      );
      final updatedJson = SnapshotSerializer.routineToJson(updatedRoutine);
      // The original run's snapshot still reports PhaseKind.focus because it was captured earlier
      final originalStillFocus = SnapshotSerializer.routineFromJson(runJson);
      expect(originalStillFocus.phases.first.kind, PhaseKind.focus);
    });
  });
}