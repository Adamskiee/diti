import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/features/routines/presentation/routine_editor_screen.dart';
import 'package:diti/src/features/routines/presentation/widgets/phase_edit_dialog.dart';
import 'package:diti/src/features/routines/presentation/widgets/phase_list_tile.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../helpers/test_fakes.dart';

void main() {
  group('RoutineEditorScreen', () {
    testWidgets('validates empty name and saves new routine', (tester) async {
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
            home: RoutineEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save while name is empty
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Routine name is required'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.byKey(const Key('routine_name_field')),
        'My Focus Routine',
      );
      await tester.pumpAndSettle();

      // Add a Phase
      await tester.tap(find.text('Add Phase'));
      await tester.pumpAndSettle();

      // Phase dialog appears
      await tester.enterText(find.byKey(const Key('phase_name_field')), 'Work');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final repo = container.read(routineRepositoryProvider);
      final all = await repo.getAllRoutines();
      expect(all.length, 1);
      expect(all.first.name, 'My Focus Routine');
      expect(all.first.phases.first.name, 'Work');
      expect(all.first.phases.first.durationMs, 1500000); // 25 min default
      expect(all.first.repeatRule.mode, RepeatMode.count);
      expect(all.first.repeatRule.count, 1);

      await db.close();
    });

    testWidgets('validates empty phases list', (tester) async {
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
            home: RoutineEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter routine name but no phases
      await tester.enterText(
        find.byKey(const Key('routine_name_field')),
        'Empty Routine',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('At least one phase is required'), findsOneWidget);

      final repo = container.read(routineRepositoryProvider);
      final all = await repo.getAllRoutines();
      expect(all, isEmpty);

      await db.close();
    });

    testWidgets(
        'edits existing routine, modifies repeat count, edits and deletes a phase',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      const initialRoutine = Routine(
        id: 'routine-edit-1',
        name: 'Existing Study Plan',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 2),
        phases: [
          RoutinePhase(
            id: 'phase-1',
            name: 'Study',
            durationMs: 1200000, // 20 min
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'phase-2',
            name: 'Short Break',
            durationMs: 300000, // 5 min
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      await container
          .read(routineRepositoryProvider)
          .saveRoutine(initialRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RoutineEditorScreen(routineId: 'routine-edit-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Routine'), findsOneWidget);
      expect(find.text('Existing Study Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Short Break'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Repeat cycles count

      // Increment repeat count
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      // Delete the 'Short Break' phase (second delete icon)
      final deleteButtons = find.byTooltip('Delete Phase');
      expect(deleteButtons, findsNWidgets(2));
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      expect(find.text('Short Break'), findsNothing);
      expect(find.text('Study'), findsOneWidget);

      // Edit the 'Study' phase
      final editButtons = find.byTooltip('Edit Phase');
      expect(editButtons, findsOneWidget);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Phase'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('phase_name_field')), 'Deep Study');
      // Increase minutes from 20 to 21
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Deep Study'), findsOneWidget);
      expect(find.text('21m · Auto'), findsOneWidget);

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final repo = container.read(routineRepositoryProvider);
      final updated = await repo.getRoutine('routine-edit-1');
      expect(updated, isNotNull);
      expect(updated!.name, 'Existing Study Plan');
      expect(updated.repeatRule.count, 3);
      expect(updated.phases.length, 1);
      expect(updated.phases.first.name, 'Deep Study');
      expect(updated.phases.first.durationMs, 1260000); // 21 min

      await db.close();
    });

    testWidgets('supports switching to forever repeat mode', (tester) async {
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
            home: RoutineEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.byKey(const Key('routine_name_field')),
        'Endless Loop',
      );
      await tester.pumpAndSettle();

      // Switch to Forever repeat mode
      await tester.tap(find.text('Forever'));
      await tester.pumpAndSettle();

      // Repeat count stepper is hidden
      expect(find.text('Repeat Cycles: '), findsNothing);

      // Add a phase
      await tester.tap(find.text('Add Phase'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final repo = container.read(routineRepositoryProvider);
      final all = await repo.getAllRoutines();
      expect(all.length, 1);
      expect(all.first.repeatRule.mode, RepeatMode.forever);

      await db.close();
    });

    testWidgets('reorders phases in the list', (tester) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      const initialRoutine = Routine(
        id: 'reorder-routine',
        name: 'Reorder Test',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p-alpha',
            name: 'Alpha',
            durationMs: 600000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'p-beta',
            name: 'Beta',
            durationMs: 300000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      await container
          .read(routineRepositoryProvider)
          .saveRoutine(initialRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RoutineEditorScreen(routineId: 'reorder-routine'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial order
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      // Trigger reorder by dragging Alpha's drag handle down past Beta
      final firstDragHandle = find.byIcon(Icons.drag_handle).first;
      final drag = await tester.startGesture(tester.getCenter(firstDragHandle));
      await tester.pump(kLongPressTimeout);
      await drag.moveBy(const Offset(0, 200));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final repo = container.read(routineRepositoryProvider);
      final updated = await repo.getRoutine('reorder-routine');
      expect(updated, isNotNull);
      expect(updated!.phases.first.name, 'Beta');
      expect(updated.phases.last.name, 'Alpha');

      await db.close();
    });
  });

  group('PhaseEditDialog', () {
    testWidgets('configures open-ended phase correctly', (tester) async {
      RoutinePhase? createdPhase;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  createdPhase = await showDialog<RoutinePhase>(
                    context: context,
                    builder: (ctx) => const PhaseEditDialog(),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Add Phase'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);

      // Toggle Open-ended
      await tester.tap(find.text('Open-ended (No time limit)'));
      await tester.pumpAndSettle();

      // Duration and At Boundary are hidden
      expect(find.text('Duration: '), findsNothing);
      expect(find.text('At Boundary'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(createdPhase, isNotNull);
      expect(createdPhase!.name, 'Focus');
      expect(createdPhase!.durationMs, isNull);
      expect(createdPhase!.transition, TransitionPolicy.manual);
      expect(createdPhase!.isValid, isTrue);
    });

    testWidgets('duration cannot be decreased below 1 minute', (tester) async {
      RoutinePhase? createdPhase;

      const initialPhase = RoutinePhase(
        id: 'p-1',
        name: 'Quick',
        durationMs: 60000, // 1 min
        transition: TransitionPolicy.auto,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  createdPhase = await showDialog<RoutinePhase>(
                    context: context,
                    builder: (ctx) =>
                        const PhaseEditDialog(phase: initialPhase),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('1 min'), findsOneWidget);

      // Minus button should be disabled (onPressed is null)
      final minusButton = tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove));
      expect(minusButton.onPressed, isNull);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(createdPhase!.durationMs, 60000);
    });

    testWidgets('cancel button dismisses without returning phase',
        (tester) async {
      RoutinePhase? createdPhase;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  createdPhase = await showDialog<RoutinePhase>(
                    context: context,
                    builder: (ctx) => const PhaseEditDialog(),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(createdPhase, isNull);
      expect(find.text('Add Phase'), findsNothing);
    });

    testWidgets('empty name field prevents submitting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhaseEditDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear the name field
      await tester.enterText(find.byKey(const Key('phase_name_field')), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Dialog is still visible because submission was ignored
      expect(find.text('Add Phase'), findsOneWidget);
    });

    testWidgets('a new phase defaults its kind from its name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhaseEditDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The default name is 'Focus', so the phase starts out as focus.
      expect(_selectedKind(tester), PhaseKind.focus);

      await tester.enterText(
        find.byKey(const Key('phase_name_field')),
        'Short Break',
      );
      await tester.pumpAndSettle();

      // The name says rest, so the kind follows it.
      expect(_selectedKind(tester), PhaseKind.rest);
    });

    testWidgets('the kind can be overridden', (tester) async {
      RoutinePhase? createdPhase;

      const focusPhase = RoutinePhase(
        id: 'p-focus',
        name: 'Deep Work',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  createdPhase = await showDialog<RoutinePhase>(
                    context: context,
                    builder: (ctx) => const PhaseEditDialog(phase: focusPhase),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(_selectedKind(tester), PhaseKind.focus);

      await tester.tap(find.text('Rest'));
      await tester.pumpAndSettle();

      expect(_selectedKind(tester), PhaseKind.rest);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(createdPhase, isNotNull);
      expect(createdPhase!.kind, PhaseKind.rest);
    });

    testWidgets('an existing phase keeps its stored kind', (tester) async {
      const restPhase = RoutinePhase(
        id: 'p-rest',
        name: 'Focus',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhaseEditDialog(phase: restPhase),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The name would infer focus, but the stored kind wins.
      expect(_selectedKind(tester), PhaseKind.rest);
    });

    testWidgets('saving an untouched existing phase keeps its stored kind',
        (tester) async {
      RoutinePhase? savedPhase;

      const restPhase = RoutinePhase(
        id: 'p-rest',
        name: 'Short Break',
        durationMs: 300000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  savedPhase = await showDialog<RoutinePhase>(
                    context: context,
                    builder: (ctx) => const PhaseEditDialog(phase: restPhase),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(savedPhase, isNotNull);
      expect(savedPhase!.kind, PhaseKind.rest);
    });

    testWidgets('the kind segments wear the app\'s focus and rest colours',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhaseEditDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final theme =
          Theme.of(tester.element(find.byType(SegmentedButton<PhaseKind>)));
      expect(_segmentLabelColor(tester, 'Focus'), theme.colorScheme.primary);
      expect(_segmentLabelColor(tester, 'Rest'), theme.colorScheme.tertiary);
    });

    testWidgets('a chosen kind is not re-derived from the name',
        (tester) async {
      RoutinePhase? createdPhase;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  createdPhase = await showDialog<RoutinePhase>(
                    context: context,
                    builder: (ctx) => const PhaseEditDialog(),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rest'));
      await tester.pumpAndSettle();

      // Once the user picked a kind, the name no longer decides it.
      await tester.enterText(
        find.byKey(const Key('phase_name_field')),
        'Deep Work',
      );
      await tester.pumpAndSettle();

      expect(_selectedKind(tester), PhaseKind.rest);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(createdPhase!.kind, PhaseKind.rest);
    });

    testWidgets('renaming an existing phase keeps its stored kind',
        (tester) async {
      const restPhase = RoutinePhase(
        id: 'p-rest',
        name: 'Focus',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.rest,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhaseEditDialog(phase: restPhase),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('phase_name_field')),
        'Deep Work',
      );
      await tester.pumpAndSettle();

      expect(_selectedKind(tester), PhaseKind.rest);
    });
  });

  group('PhaseListTile', () {
    testWidgets('renders timed phase and responds to edit and delete',
        (tester) async {
      var editCalled = false;
      var deleteCalled = false;

      const phase = RoutinePhase(
        id: 'phase-timed',
        name: 'Cardio',
        durationMs: 900000, // 15 min
        transition: TransitionPolicy.auto,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhaseListTile(
              phase: phase,
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('15m · Auto'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit Phase'));
      expect(editCalled, isTrue);

      await tester.tap(find.byTooltip('Delete Phase'));
      expect(deleteCalled, isTrue);
    });

    testWidgets('renders open-ended phase as Open-ended · Manual',
        (tester) async {
      const phase = RoutinePhase(
        id: 'phase-open',
        name: 'Free Writing',
        durationMs: null,
        transition: TransitionPolicy.manual,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhaseListTile(
              phase: phase,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Free Writing'), findsOneWidget);
      expect(find.text('Open-ended · Manual'), findsOneWidget);
    });

    testWidgets('shows a chip naming the kind of each phase', (tester) async {
      const focusPhase = RoutinePhase(
        id: 'phase-focus',
        name: 'Deep Work',
        durationMs: 1500000,
        transition: TransitionPolicy.auto,
        kind: PhaseKind.focus,
      );
      const restPhase = RoutinePhase(
        id: 'phase-rest',
        name: 'Short Break',
        durationMs: 300000,
        transition: TransitionPolicy.manual,
        kind: PhaseKind.rest,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PhaseListTile(
                  phase: focusPhase,
                  onEdit: () {},
                  onDelete: () {},
                ),
                PhaseListTile(
                  phase: restPhase,
                  onEdit: () {},
                  onDelete: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);

      // Focus wears the primary colour, rest the tertiary one - the same
      // convention the rest of the app uses for the two kinds.
      final theme = Theme.of(tester.element(find.byType(PhaseListTile).first));
      expect(_chipLabelColor(tester, 'Focus'), theme.colorScheme.primary);
      expect(_chipLabelColor(tester, 'Rest'), theme.colorScheme.tertiary);
    });

    testWidgets('lays out without overflowing on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const phase = RoutinePhase(
        id: 'phase-open',
        name: 'A long phase name',
        durationMs: null,
        transition: TransitionPolicy.manual,
        kind: PhaseKind.rest,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhaseListTile(
              phase: phase,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Rest'), findsOneWidget);
    });
  });
}

/// The kind the phase dialog currently has selected.
PhaseKind _selectedKind(WidgetTester tester) {
  final button = tester.widget<SegmentedButton<PhaseKind>>(
    find.byType(SegmentedButton<PhaseKind>),
  );
  return button.selected.single;
}

/// The colour of the label of the kind chip reading [label].
Color? _chipLabelColor(WidgetTester tester, String label) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.widgetWithText(Chip, label),
      matching: find.byType(Text),
    ),
  );
  return text.style?.color;
}

/// The colour of the label of the kind segment reading [label].
Color? _segmentLabelColor(WidgetTester tester, String label) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byType(SegmentedButton<PhaseKind>),
      matching: find.text(label),
    ),
  );
  return text.style?.color;
}
