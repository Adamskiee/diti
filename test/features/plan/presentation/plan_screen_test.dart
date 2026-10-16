import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/di/database_provider.dart';
import 'package:focus_flow/src/core/di/notification_providers.dart';
import 'package:focus_flow/src/core/di/repositories_provider.dart';
import 'package:focus_flow/src/core/di/timer_engine_provider.dart';
import 'package:focus_flow/src/features/plan/presentation/plan_screen.dart';
import 'package:focus_flow/src/features/plan/presentation/widgets/date_selector_strip.dart';
import 'package:focus_flow/src/features/plan/presentation/widgets/plan_block_card.dart';
import 'package:focus_flow/src/features/plan/presentation/widgets/plan_block_dialog.dart';
import 'package:focus_flow/src/features/plan/providers/plan_providers.dart';
import 'package:focus_flow/src/features/timer/presentation/active_timer_screen.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../helpers/test_fakes.dart';

void main() {
  group('PlanScreen', () {
    testWidgets('renders empty state and FAB opens PlanBlockDialog',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('No blocks scheduled for this day'),
          findsOneWidget);
      expect(find.byType(DateSelectorStrip), findsOneWidget);

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(PlanBlockDialog), findsOneWidget);
      expect(find.text('Schedule Block'), findsOneWidget);

      await db.close();
      container.dispose();
    });

    testWidgets('renders list of PlanBlockCards and supports deletion',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        ],
      );

      final planRepo = container.read(planBlockRepositoryProvider);

      // Seed a block
      final block = PlanBlock(
        id: 'block-1',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 30 * 60 * 1000,
        routineId: 'Morning Review',
        status: PlanBlockStatus.scheduled,
      );
      await planRepo.createPlanBlock(block);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlanBlockCard), findsOneWidget);
      expect(find.text('Morning Review'), findsOneWidget);

      // Open popup menu on the card
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete in menu
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Block'), findsOneWidget);
      expect(
          find.text('Delete "Morning Review" from schedule?'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      // Card should be gone and empty state displayed
      expect(find.byType(PlanBlockCard), findsNothing);
      expect(find.textContaining('No blocks scheduled for this day'),
          findsOneWidget);

      await db.close();
      container.dispose();
    });

    testWidgets('opens edit dialog when editing a block', (tester) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        ],
      );

      final planRepo = container.read(planBlockRepositoryProvider);

      final block = PlanBlock(
        id: 'block-edit',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 45 * 60 * 1000,
        routineId: 'Deep Focus',
        status: PlanBlockStatus.scheduled,
      );
      await planRepo.createPlanBlock(block);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PlanBlockCard), findsOneWidget);

      // Open popup menu on card
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Edit in menu
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(PlanBlockDialog), findsOneWidget);
      expect(find.text('Edit Block'), findsOneWidget);

      await db.close();
      container.dispose();
    });

    testWidgets('starts block routine and pushes ActiveTimerScreen',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      final planRepo = container.read(planBlockRepositoryProvider);
      final routineRepo = container.read(routineRepositoryProvider);

      const testRoutine = Routine(
        id: 'r-focus',
        name: 'Deep Focus',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p-focus',
            name: 'Focus Phase',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      await routineRepo.saveRoutine(testRoutine);

      final block = PlanBlock(
        id: 'block-timer',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 25 * 60 * 1000,
        routineId: 'Deep Focus',
        status: PlanBlockStatus.scheduled,
      );
      await planRepo.createPlanBlock(block);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Start Block on card
      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      // ActiveTimerScreen should be pushed
      expect(find.byType(ActiveTimerScreen), findsOneWidget);
      expect(find.text('Focus Phase'), findsWidgets);

      await db.close();
      container.dispose();
    });
  });
}
