import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/features/plan/presentation/widgets/conflict_warning_banner.dart';
import 'package:diti/src/features/plan/presentation/widgets/plan_block_dialog.dart';
import 'package:diti/src/features/plan/providers/plan_providers.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';

import '../../../../../test/helpers/test_fakes.dart';

void main() {
  group('PlanBlockDialog', () {
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

    Future<void> seedRoutines(DitiDatabase database) async {
      final repo = DriftRoutineRepository(database);
      await repo.saveRoutine(
        const Routine(
          id: 'r1',
          name: 'Morning Routine',
          phases: [
            RoutinePhase(
              id: 'p1',
              name: 'Stretch',
              durationMs: 600000, // 10m
              transition: TransitionPolicy.auto,
            ),
            RoutinePhase(
              id: 'p2',
              name: 'Meditation',
              durationMs: 1200000, // 20m
              transition: TransitionPolicy.auto,
            ),
          ],
          repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        ),
      );
      await repo.saveRoutine(
        const Routine(
          id: 'r2',
          name: 'Pomodoro Double',
          phases: [
            RoutinePhase(
              id: 'p3',
              name: 'Focus',
              durationMs: 1500000, // 25m
              transition: TransitionPolicy.auto,
            ),
          ],
          repeatRule: RepeatRule(mode: RepeatMode.count, count: 2), // 50m total
        ),
      );
    }

    testWidgets('schedules custom activity and returns valid PlanBlock',
        (tester) async {
      PlanBlock? result;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<PlanBlock>(
                      context: ctx,
                      builder: (dCtx) => PlanBlockDialog(
                        planDate: '2026-10-16',
                        initialStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Block'), findsOneWidget);

      // Switch to Custom Activity
      await tester.tap(find.text('Custom Activity'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.byKey(const Key('plan_title_field')),
        'Reading Paper',
      );
      await tester.pumpAndSettle();

      // Tap Save Block
      await tester.tap(find.text('Save Block'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.routineId, 'Reading Paper');
      expect(result!.planDate, '2026-10-16');
      expect(result!.plannedDurationMs, 50 * 60000);
      expect(result!.scheduledStartUtc, DateTime.utc(2026, 10, 16, 10, 0));
      expect(result!.status, PlanBlockStatus.scheduled);
    });

    testWidgets('loads available routines and applies calculated duration',
        (tester) async {
      await seedRoutines(db);

      PlanBlock? result;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<PlanBlock>(
                      context: ctx,
                      builder: (dCtx) => PlanBlockDialog(
                        planDate: '2026-10-16',
                        initialStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // First routine 'Morning Routine' (10m + 20m = 30m)
      expect(find.text('Morning Routine'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);

      // Change dropdown to 'Pomodoro Double' (25m * 2 = 50m)
      await tester.tap(find.text('Morning Routine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pomodoro Double').last);
      await tester.pumpAndSettle();

      expect(find.text('50m'), findsOneWidget);

      await tester.tap(find.text('Save Block'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.routineId, 'Pomodoro Double');
      expect(result!.plannedDurationMs, 50 * 60000);
    });

    testWidgets(
        'duration stepper adjusts duration by 5 minutes and disables at 5m',
        (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDialog<PlanBlock>(
                    context: ctx,
                    builder: (dCtx) => PlanBlockDialog(
                      planDate: '2026-10-16',
                      initialStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Default duration is 50m
      expect(find.text('50m'), findsOneWidget);

      // Add 5 min -> 55m
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('55m'), findsOneWidget);

      // Subtract until 5m
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.remove));
        await tester.pumpAndSettle();
      }
      expect(find.text('5m'), findsOneWidget);

      // Subtract button should now be disabled (IconButton onPressed is null)
      final removeButton = tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove));
      expect(removeButton.onPressed, isNull);
    });

    testWidgets(
        'displays ConflictWarningBanner when tentative time overlaps existing block',
        (tester) async {
      // Seed an existing plan block from 10:00 to 11:00 UTC
      final planRepo = container.read(planBlockRepositoryProvider);
      await planRepo.createPlanBlock(
        PlanBlock(
          id: 'existing-block-1',
          planDate: '2026-10-16',
          scheduledStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
          timezoneId: 'UTC',
          plannedDurationMs: 60 * 60000,
          routineId: 'Existing Work',
        ),
      );

      // Warm up daily plan controller
      await container.read(dailyPlanControllerProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDialog<PlanBlock>(
                    context: ctx,
                    builder: (dCtx) => PlanBlockDialog(
                      planDate: '2026-10-16',
                      // Overlapping start time: 10:30 UTC
                      initialStartUtc: DateTime.utc(2026, 10, 16, 10, 30),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should display conflict warning
      expect(find.byType(ConflictWarningBanner), findsOneWidget);
      expect(find.textContaining('Existing Work'), findsOneWidget);
    });

    testWidgets('shows validation error when title is empty', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showDialog<PlanBlock>(
                    context: ctx,
                    builder: (dCtx) => PlanBlockDialog(
                      planDate: '2026-10-16',
                      initialStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Custom Activity with empty title
      await tester.tap(find.text('Custom Activity'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Block'));
      await tester.pumpAndSettle();

      expect(find.text('Activity title is required'), findsOneWidget);
    });

    testWidgets('cancels dialog without returning a block', (tester) async {
      PlanBlock? result;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<PlanBlock>(
                      context: ctx,
                      builder: (dCtx) => PlanBlockDialog(
                        planDate: '2026-10-16',
                        initialStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(PlanBlockDialog), findsNothing);
      expect(result, isNull);
    });

    testWidgets('edits existing block preserving id and properties',
        (tester) async {
      final existing = PlanBlock(
        id: 'block-to-edit',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 45 * 60000,
        routineId: 'Existing Task',
        status: PlanBlockStatus.inProgress,
        actualDurationMs: 120000,
        sessionId: 'session-xyz',
      );

      PlanBlock? result;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<PlanBlock>(
                      context: ctx,
                      builder: (dCtx) => PlanBlockDialog(
                        planDate: '2026-10-16',
                        initialStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
                        existingBlock: existing,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Block'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);

      await tester.tap(find.text('Save Block'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.id, 'block-to-edit');
      expect(result!.routineId, 'Existing Task');
      expect(result!.plannedDurationMs, 45 * 60000);
      expect(result!.status, PlanBlockStatus.inProgress);
      expect(result!.actualDurationMs, 120000);
      expect(result!.sessionId, 'session-xyz');
    });

    testWidgets(
        'picks new start time using time picker and updates block start time',
        (tester) async {
      PlanBlock? result;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<PlanBlock>(
                      context: ctx,
                      builder: (dCtx) => PlanBlockDialog(
                        planDate: '2026-10-16',
                        initialStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Switch to custom activity
      await tester.tap(find.text('Custom Activity'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('plan_title_field')),
        'Workout',
      );
      await tester.pumpAndSettle();

      // Tap start time button
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();

      // TimePicker dialog should be visible; confirm by tapping 'OK'
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Block'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.routineId, 'Workout');
    });
  });
}
