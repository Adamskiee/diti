import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/di/database_provider.dart';
import 'package:focus_flow/src/core/di/repositories_provider.dart';
import 'package:focus_flow/src/features/routines/presentation/routine_list_screen.dart';
import 'package:focus_flow/src/features/routines/presentation/widgets/routine_card.dart';
import 'package:focus_flow/src/features/routines/providers/routines_providers.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../helpers/test_fakes.dart';

void main() {
  group('RoutineListScreen', () {
    testWidgets('RoutineListScreen displays routine cards and triggers duplicate',
        (tester) async {
      final db = createInMemoryTestDatabase();
      const testRoutine = Routine(
        id: 'test-routine-1',
        name: 'Sample Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 2),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 1200000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RoutineListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sample Routine'), findsOneWidget);
      // 20 min * 2 = 40 min
      expect(find.text('40m'), findsOneWidget);
      expect(find.text('Work (20m)'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);

      // Find and tap overflow menu
      final overflowButton =
          find.byKey(const Key('routine_overflow_test-routine-1'));
      expect(overflowButton, findsOneWidget);
      await tester.tap(overflowButton);
      await tester.pumpAndSettle();

      // Tap Duplicate
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(find.text('Sample Routine (Copy)'), findsOneWidget);

      container.dispose();
      await db.close();
    });

    testWidgets('RoutineListScreen triggers delete with confirmation dialog',
        (tester) async {
      final db = createInMemoryTestDatabase();
      const testRoutine = Routine(
        id: 'test-routine-delete',
        name: 'Delete Me',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            durationMs: 600000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RoutineListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Delete Me'), findsOneWidget);

      // Open overflow menu
      await tester.tap(find.byKey(const Key('routine_overflow_test-routine-delete')));
      await tester.pumpAndSettle();

      // Tap Delete in menu
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Routine'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Delete Me"?'), findsOneWidget);

      // Tap Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Me'), findsOneWidget);

      // Open overflow menu again and confirm delete
      await tester.tap(find.byKey(const Key('routine_overflow_test-routine-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Delete in dialog (there is one Delete on dialog action button)
      final dialogDeleteButton = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsNothing);
      expect(find.text('No routines found. Tap + to create one!'), findsOneWidget);

      container.dispose();
      await db.close();
    });

    testWidgets('RoutineListScreen callbacks for start, card tap, and fab tap',
        (tester) async {
      final db = createInMemoryTestDatabase();
      const testRoutine = Routine(
        id: 'test-callbacks',
        name: 'Callback Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Sprint',
            durationMs: 300000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      Routine? startedRoutine;
      String? editedRoutineId;
      var fabTapped = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: RoutineListScreen(
              onStartRoutine: (routine) => startedRoutine = routine,
              onEditRoutine: (routineId) {
                if (routineId == null) {
                  fabTapped = true;
                } else {
                  editedRoutineId = routineId;
                }
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap start button
      await tester.tap(find.text('Start'));
      expect(startedRoutine?.id, 'test-callbacks');

      // Tap routine card
      await tester.tap(find.text('Callback Routine'));
      expect(editedRoutineId, 'test-callbacks');

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      expect(fabTapped, isTrue);

      container.dispose();
      await db.close();
    });

    testWidgets('RoutineListScreen displays empty state when no routines',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RoutineListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No routines found. Tap + to create one!'), findsOneWidget);

      container.dispose();
      await db.close();
    });
  });

  group('RoutineCard', () {
    testWidgets('renders open-ended phase and forever repeat correctly',
        (tester) async {
      const routine = Routine(
        id: 'open-ended-routine',
        name: 'Open Routine',
        repeatRule: RepeatRule(mode: RepeatMode.forever),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Flow',
            durationMs: null,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: routine,
              onStart: () {},
              onTap: () {},
              onDuplicate: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Open-ended'), findsOneWidget); // totalDurationMs chip
      expect(find.text('∞'), findsOneWidget);
      expect(find.text('Flow (Open-ended)'), findsOneWidget);
    });

    testWidgets('renders count 1 as "Once"', (tester) async {
      const routine = Routine(
        id: 'once-routine',
        name: 'Single Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Task',
            durationMs: 300000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: routine,
              onStart: () {},
              onTap: () {},
              onDuplicate: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Once'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
    });
  });

  group('RoutineListController', () {
    test('sorts routines alphabetically and supports duplicate and delete',
        () async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      final repo = container.read(routineRepositoryProvider);
      const zRoutine = Routine(
        id: 'z-id',
        name: 'Zebra Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'zp1',
            name: 'Phase Z',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
      const aRoutine = Routine(
        id: 'a-id',
        name: 'Alpha Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'ap1',
            name: 'Phase A',
            durationMs: 120000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      await repo.saveRoutine(zRoutine);
      await repo.saveRoutine(aRoutine);

      final initialList =
          await container.read(routineListControllerProvider.future);
      expect(initialList.length, 2);
      expect(initialList[0].name, 'Alpha Routine');
      expect(initialList[1].name, 'Zebra Routine');

      // Duplicate Alpha
      final controller =
          container.read(routineListControllerProvider.notifier);
      await controller.duplicateRoutine(aRoutine);

      final afterDup =
          await container.read(routineListControllerProvider.future);
      expect(afterDup.length, 3);
      final duplicated =
          afterDup.firstWhere((r) => r.name == 'Alpha Routine (Copy)');
      expect(duplicated.id, isNot('a-id'));
      expect(duplicated.phases.length, 1);
      expect(duplicated.phases.first.id, isNot('ap1'));
      expect(duplicated.phases.first.name, 'Phase A');
      expect(duplicated.phases.first.durationMs, 120000);
      expect(duplicated.phases.first.transition, TransitionPolicy.manual);

      // Delete Zebra
      await controller.deleteRoutine('z-id');
      final afterDelete =
          await container.read(routineListControllerProvider.future);
      expect(afterDelete.length, 2);
      expect(afterDelete.any((r) => r.id == 'z-id'), isFalse);

      container.dispose();
      await db.close();
    });
  });
}
