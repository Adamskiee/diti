import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../lib/src/mappers/snapshot_serializer.dart';

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
  });
}
