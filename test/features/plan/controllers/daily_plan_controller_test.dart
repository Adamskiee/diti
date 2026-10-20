import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/features/plan/presentation/controllers/daily_plan_controller.dart';
import 'package:diti/src/features/plan/providers/plan_providers.dart';
import 'package:diti_database/diti_database.dart';

import '../../../helpers/test_fakes.dart';

void main() {
  group('DailyPlanController', () {
    late DitiDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = createInMemoryTestDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
        'loads blocks, calculates conflicts, and performs CRUD operations',
        () async {
      final DailyPlanController controller =
          container.read(dailyPlanControllerProvider.notifier);
      final initial = await container.read(dailyPlanControllerProvider.future);
      expect(initial.blocks, isEmpty);
      expect(initial.dateString, '2026-10-16');
      expect(initial.totalPlannedMs, 0);
      expect(initial.totalActualMs, 0);

      // Create block 1 (09:00 - 10:00)
      final block1 = PlanBlock(
        id: 'b1',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 3600000,
        routineId: 'Deep Work',
      );
      await controller.createBlock(block1);

      var state = await container.read(dailyPlanControllerProvider.future);
      expect(state.blocks.length, 1);
      expect(state.totalPlannedMs, 3600000);
      expect(state.totalActualMs, 0);
      expect(state.hasConflict('b1'), isFalse);

      // Create block 2 overlapping (09:30 - 10:30)
      final block2 = PlanBlock(
        id: 'b2',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 30),
        timezoneId: 'UTC',
        plannedDurationMs: 3600000,
        routineId: 'Reading',
      );
      await controller.createBlock(block2);

      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.blocks.length, 2);
      expect(state.totalPlannedMs, 7200000);
      expect(state.hasConflict('b1'), isTrue);
      expect(state.hasConflict('b2'), isTrue);

      // Update block 1 to end at 09:30 (avoiding overlap)
      final updatedBlock1 = PlanBlock(
        id: 'b1',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000, // 30 min -> 09:00 - 09:30
        routineId: 'Deep Work',
        actualDurationMs: 1800000,
      );
      await controller.updateBlock(updatedBlock1);

      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.blocks.length, 2);
      expect(state.totalPlannedMs, 1800000 + 3600000);
      expect(state.totalActualMs, 1800000);
      expect(state.hasConflict('b1'), isFalse);
      expect(state.hasConflict('b2'), isFalse);

      // Delete block 2
      await controller.deleteBlock('b2');
      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.blocks.length, 1);
      expect(state.blocks.first.id, 'b1');
      expect(state.hasConflict('b1'), isFalse);
    });

    test('blocks are sorted by scheduledStartUtc ascending', () async {
      final DailyPlanController controller =
          container.read(dailyPlanControllerProvider.notifier);
      await container.read(dailyPlanControllerProvider.future);

      final lateBlock = PlanBlock(
        id: 'late',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        routineId: 'Late Meeting',
      );
      final earlyBlock = PlanBlock(
        id: 'early',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 8, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        routineId: 'Morning Routine',
      );

      await controller.createBlock(lateBlock);
      await controller.createBlock(earlyBlock);

      final state = await container.read(dailyPlanControllerProvider.future);
      expect(state.blocks.map((b) => b.id).toList(), ['early', 'late']);
    });

    test('checkTentativeConflict checks against loaded state blocks', () async {
      final DailyPlanController controller =
          container.read(dailyPlanControllerProvider.notifier);

      final existingBlock = PlanBlock(
        id: 'b1',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 3600000, // 09:00 - 10:00
        routineId: 'Focus Session',
      );
      await controller.createBlock(existingBlock);

      // Tentative block overlapping 09:30 - 10:30
      final conflicts = controller.checkTentativeConflict(
        startUtc: DateTime.utc(2026, 10, 16, 9, 30),
        durationMs: 3600000,
      );
      expect(conflicts.length, 1);
      expect(conflicts.first.conflictingBlockId, 'b1');

      // Tentative block excluding b1
      final excludedConflicts = controller.checkTentativeConflict(
        startUtc: DateTime.utc(2026, 10, 16, 9, 30),
        durationMs: 3600000,
        excludeBlockId: 'b1',
      );
      expect(excludedConflicts, isEmpty);

      // Tentative block disjoint 11:00 - 12:00
      final noConflicts = controller.checkTentativeConflict(
        startUtc: DateTime.utc(2026, 10, 16, 11, 0),
        durationMs: 3600000,
      );
      expect(noConflicts, isEmpty);
    });

    test('date navigation updates selected date and reloads blocks', () async {
      final DailyPlanController controller =
          container.read(dailyPlanControllerProvider.notifier);
      var state = await container.read(dailyPlanControllerProvider.future);
      expect(state.dateString, '2026-10-16');

      // Add block on 2026-10-16
      await controller.createBlock(
        PlanBlock(
          id: 'b16',
          planDate: '2026-10-16',
          scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
          timezoneId: 'UTC',
          plannedDurationMs: 3600000,
          routineId: 'Oct 16 Routine',
        ),
      );

      // Add block on 2026-10-17
      await controller.createBlock(
        PlanBlock(
          id: 'b17',
          planDate: '2026-10-17',
          scheduledStartUtc: DateTime.utc(2026, 10, 17, 9, 0),
          timezoneId: 'UTC',
          plannedDurationMs: 1800000,
          routineId: 'Oct 17 Routine',
        ),
      );

      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.blocks.length, 1);
      expect(state.blocks.first.id, 'b16');

      // Navigate to next day
      controller.nextDay();
      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.dateString, '2026-10-17');
      expect(state.blocks.length, 1);
      expect(state.blocks.first.id, 'b17');

      // Navigate to previous day
      controller.previousDay();
      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.dateString, '2026-10-16');
      expect(state.blocks.length, 1);
      expect(state.blocks.first.id, 'b16');

      // Set arbitrary date
      controller.setDate(DateTime(2026, 10, 20));
      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.dateString, '2026-10-20');
      expect(state.blocks, isEmpty);

      // Set today
      controller.setToday();
      final today = DateTime.now();
      final expectedTodayString =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      state = await container.read(dailyPlanControllerProvider.future);
      expect(state.dateString, expectedTodayString);
    });
  });
}
