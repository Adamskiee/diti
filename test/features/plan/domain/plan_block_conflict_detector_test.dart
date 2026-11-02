import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/plan/domain/plan_block_conflict.dart';
import 'package:diti/src/features/plan/domain/plan_block_conflict_detector.dart';
import 'package:diti_database/diti_database.dart';

void main() {
  group('PlanBlockConflictDetector', () {
    final baseDate = DateTime.utc(2026, 10, 16, 9, 0); // 09:00 AM

    PlanBlock createBlock({
      required String id,
      required DateTime start,
      required int durationMinutes,
      String? routineId,
    }) {
      return PlanBlock(
        id: id,
        planDate: '2026-10-16',
        scheduledStartUtc: start,
        timezoneId: 'UTC',
        plannedDurationMs: durationMinutes * 60000,
        routineId: routineId,
      );
    }

    test('empty or single block list produces no conflicts', () {
      expect(PlanBlockConflictDetector.detectConflicts([]), isEmpty);

      final single = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 60,
      );
      expect(PlanBlockConflictDetector.detectConflicts([single]), isEmpty);
    });

    test('disjoint blocks produce no conflicts', () {
      final block1 = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 60, // 09:00 - 10:00
      );
      final block2 = createBlock(
        id: 'b2',
        start: baseDate.add(const Duration(hours: 2)), // 11:00 - 12:00
        durationMinutes: 60,
      );

      final conflicts =
          PlanBlockConflictDetector.detectConflicts([block1, block2]);
      expect(conflicts, isEmpty);
    });

    test('exact boundary touching is not a conflict', () {
      final block1 = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 60, // 09:00 - 10:00
      );
      final block2 = createBlock(
        id: 'b2',
        start: baseDate.add(const Duration(hours: 1)), // 10:00 - 11:00
        durationMinutes: 60,
      );

      final conflicts =
          PlanBlockConflictDetector.detectConflicts([block1, block2]);
      expect(conflicts, isEmpty);
    });

    test('overlapping blocks are flagged for both blocks', () {
      final block1 = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 60, // 09:00 - 10:00
      );
      final block2 = createBlock(
        id: 'b2',
        start: baseDate.add(const Duration(minutes: 30)), // 09:30 - 10:30
        durationMinutes: 60,
      );

      final conflicts =
          PlanBlockConflictDetector.detectConflicts([block1, block2]);
      expect(conflicts.containsKey('b1'), isTrue);
      expect(conflicts.containsKey('b2'), isTrue);
      expect(conflicts['b1']!.first.conflictingBlockId, 'b2');
      expect(conflicts['b2']!.first.conflictingBlockId, 'b1');
    });

    test('enclosed block detects conflict', () {
      final outer = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 120, // 09:00 - 11:00
      );
      final inner = createBlock(
        id: 'b2',
        start: baseDate.add(const Duration(minutes: 30)), // 09:30 - 10:15
        durationMinutes: 45,
      );

      final conflicts =
          PlanBlockConflictDetector.detectConflicts([outer, inner]);
      expect(conflicts['b1']!.length, 1);
      expect(conflicts['b2']!.length, 1);
    });

    test('multiple overlapping blocks record all conflict pairs', () {
      final block1 = createBlock(
        id: 'b1',
        start: baseDate, // 09:00 - 10:00
        durationMinutes: 60,
        routineId: 'Deep Work',
      );
      final block2 = createBlock(
        id: 'b2',
        start: baseDate.add(const Duration(minutes: 30)), // 09:30 - 10:30
        durationMinutes: 60,
        routineId: 'Meeting',
      );
      final block3 = createBlock(
        id: 'b3',
        start: baseDate.add(const Duration(minutes: 45)), // 09:45 - 10:15
        durationMinutes: 30,
        routineId: 'Sync',
      );

      final conflicts =
          PlanBlockConflictDetector.detectConflicts([block1, block2, block3]);

      // b1 overlaps with b2 and b3
      expect(conflicts['b1']!.length, 2);
      expect(
        conflicts['b1']!.map((c) => c.conflictingBlockId),
        containsAll(['b2', 'b3']),
      );

      // b2 overlaps with b1 and b3
      expect(conflicts['b2']!.length, 2);
      expect(
        conflicts['b2']!.map((c) => c.conflictingBlockId),
        containsAll(['b1', 'b3']),
      );

      // b3 overlaps with b1 and b2
      expect(conflicts['b3']!.length, 2);
      expect(
        conflicts['b3']!.map((c) => c.conflictingBlockId),
        containsAll(['b1', 'b2']),
      );
    });

    test('checkTentativeConflict detects overlap and respects excludeBlockId',
        () {
      final existing = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 60, // 09:00 - 10:00
      );

      // Candidate 09:30 - 10:30
      final conflicts = PlanBlockConflictDetector.checkTentativeConflict(
        startUtc: baseDate.add(const Duration(minutes: 30)),
        durationMs: 60 * 60000,
        existingBlocks: [existing],
      );
      expect(conflicts.length, 1);
      expect(conflicts.first.conflictingBlockId, 'b1');

      // Candidate matches b1, but excludes b1 (e.g. editing b1)
      final excludedConflicts =
          PlanBlockConflictDetector.checkTentativeConflict(
        startUtc: baseDate,
        durationMs: 60 * 60000,
        existingBlocks: [existing],
        excludeBlockId: 'b1',
      );
      expect(excludedConflicts, isEmpty);
    });

    test('checkTentativeConflict returns empty when touching boundary', () {
      final existing = createBlock(
        id: 'b1',
        start: baseDate,
        durationMinutes: 60, // 09:00 - 10:00
      );

      // Candidate 10:00 - 11:00 (exact boundary touch at end)
      final afterTouch = PlanBlockConflictDetector.checkTentativeConflict(
        startUtc: baseDate.add(const Duration(hours: 1)),
        durationMs: 60 * 60000,
        existingBlocks: [existing],
      );
      expect(afterTouch, isEmpty);

      // Candidate 08:00 - 09:00 (exact boundary touch at start)
      final beforeTouch = PlanBlockConflictDetector.checkTentativeConflict(
        startUtc: baseDate.subtract(const Duration(hours: 1)),
        durationMs: 60 * 60000,
        existingBlocks: [existing],
      );
      expect(beforeTouch, isEmpty);
    });

    test('PlanBlockConflict value equality and hashCode work correctly', () {
      final conflict1 = PlanBlockConflict(
        blockId: 'b1',
        conflictingBlockId: 'b2',
        conflictingTitle: 'Task 2',
        conflictingStartUtc: baseDate,
        conflictingEndUtc: baseDate.add(const Duration(hours: 1)),
        description: 'Overlap',
      );

      final conflict2 = PlanBlockConflict(
        blockId: 'b1',
        conflictingBlockId: 'b2',
        conflictingTitle: 'Different title',
        conflictingStartUtc: baseDate,
        conflictingEndUtc: baseDate.add(const Duration(hours: 1)),
        description: 'Different desc',
      );

      final conflict3 = PlanBlockConflict(
        blockId: 'b1',
        conflictingBlockId: 'b3',
        conflictingTitle: 'Task 3',
        conflictingStartUtc: baseDate,
        conflictingEndUtc: baseDate.add(const Duration(hours: 1)),
        description: 'Overlap',
      );

      expect(conflict1, equals(conflict2));
      expect(conflict1.hashCode, equals(conflict2.hashCode));
      expect(conflict1, isNot(equals(conflict3)));
    });
  });
}
