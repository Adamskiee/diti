import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';

void main() {
  const routine = Routine(
    id: 'r1',
    name: 'Deep Focus',
    repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
    phases: [
      RoutinePhase(
        id: 'p1',
        name: 'Sprint',
        durationMs: 25 * 60 * 1000,
        transition: TransitionPolicy.auto,
      ),
    ],
  );

  testWidgets('SessionDetailSheet displays routine name, duration and outcome', (tester) async {
    final session = SessionRecord(
      sessionId: 's_test_1',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    expect(find.text('Deep Focus'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Delete Session'), findsOneWidget);
  });

  testWidgets('SessionDetailSheet displays Quick Timer fallback and linked block', (tester) async {
    final session = SessionRecord(
      sessionId: 's_test_2',
      routineName: '   ',
      planBlockId: 'block_42',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 15),
      totalDurationMs: 15 * 60 * 1000,
      outcome: SessionOutcome.cancelled,
      routineSnapshot: routine,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    expect(find.text('Quick Timer'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Linked Block'), findsOneWidget);
    expect(find.text('block_42'), findsOneWidget);
  });

  testWidgets('the phase log lists each phase with its kind and duration', (tester) async {
    // A session of one focus phase and one rest phase: the log shows each
    // phase's name, the kind it ran as and its own active time.
    final session = SessionRecord(
      sessionId: 's_test_4',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
      totalDurationMs: 30 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
      events: [
        SessionEventRecord(
          eventId: 'e1',
          sessionId: 's_test_4',
          eventType: 'phase_finished',
          occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
          phaseId: 'p1',
          phaseName: 'Sprint',
          durationMs: 25 * 60 * 1000,
          outcome: 'finished',
          kind: PhaseKind.focus,
        ),
        SessionEventRecord(
          eventId: 'e2',
          sessionId: 's_test_4',
          eventType: 'phase_finished',
          occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
          phaseId: 'p2',
          phaseName: 'Break',
          durationMs: 5 * 60 * 1000,
          outcome: 'finished',
          kind: PhaseKind.rest,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    expect(find.text('Phase Log'), findsOneWidget);
    expect(find.text('Sprint'), findsOneWidget);
    expect(find.text('Break'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);

    // The chips wear the app's focus and rest colours.
    final theme = Theme.of(tester.element(find.byType(SessionDetailSheet)));
    expect(
      tester.widget<Text>(find.text('Focus')).style?.color,
      theme.colorScheme.primary,
    );
    expect(
      tester.widget<Text>(find.text('Rest')).style?.color,
      theme.colorScheme.tertiary,
    );
  });

  testWidgets('a skipped phase is marked as skipped', (tester) async {
    // The break was abandoned after three minutes: the log shows the time it
    // actually took, but it must not read like a phase that ran to its end.
    final session = SessionRecord(
      sessionId: 's_test_7',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 28),
      totalDurationMs: 28 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
      events: [
        SessionEventRecord(
          eventId: 'e1',
          sessionId: 's_test_7',
          eventType: 'phase_finished',
          occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
          phaseId: 'p1',
          phaseName: 'Sprint',
          durationMs: 25 * 60 * 1000,
          outcome: 'finished',
          kind: PhaseKind.focus,
        ),
        SessionEventRecord(
          eventId: 'e2',
          sessionId: 's_test_7',
          eventType: 'phase_skipped',
          occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 28),
          phaseId: 'p2',
          phaseName: 'Break',
          durationMs: 3 * 60 * 1000,
          outcome: 'skipped',
          kind: PhaseKind.rest,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    // The skipped row carries the marker, the finished row does not.
    final skippedRow =
        find.ancestor(of: find.text('Break'), matching: find.byType(Row));
    expect(
      find.descendant(of: skippedRow, matching: find.text('Skipped')),
      findsOneWidget,
    );
    final finishedRow =
        find.ancestor(of: find.text('Sprint'), matching: find.byType(Row));
    expect(
      find.descendant(of: finishedRow, matching: find.text('Skipped')),
      findsNothing,
    );

    // Both rows still show the time the phase actually took.
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);
  });

  testWidgets('dragging the sheet chrome dismisses the sheet', (tester) async {
    // A long log: the chrome has to stay draggable even when the phase log
    // is long enough to scroll on its own.
    await openSessionSheet(tester, _longLogSession(routine));

    expect(find.byType(SessionDetailSheet), findsOneWidget);

    // The drag starts on the sheet's title - its chrome, not the phase log.
    // The sheet follows the finger: the gesture reaches the sheet's own drag
    // recogniser instead of being swallowed by a scrollable.
    final topBefore = tester.getRect(find.byType(SessionDetailSheet)).top;
    await tester.drag(find.text('Deep Focus'), const Offset(0, 60));
    await tester.pump();
    expect(
      tester.getRect(find.byType(SessionDetailSheet)).top,
      greaterThan(topBefore),
    );
    await tester.pumpAndSettle();

    // And a flick down on the chrome dismisses the sheet.
    await tester.fling(find.text('Deep Focus'), const Offset(0, 200), 1000);
    await tester.pumpAndSettle();

    expect(find.byType(SessionDetailSheet), findsNothing);
  });

  testWidgets('dragging the phase log scrolls the log, not the sheet',
      (tester) async {
    await openSessionSheet(tester, _longLogSession(routine));

    expect(find.byType(SessionDetailSheet), findsOneWidget);

    final sheetTop = tester.getRect(find.byType(SessionDetailSheet)).top;
    final log = find.descendant(
      of: find.byKey(const Key('phase_log')),
      matching: find.byType(Scrollable),
    );

    // Dragging up on the log scrolls the log and leaves the sheet where it
    // is: only the chrome drags the sheet.
    await tester.drag(find.text('Sprint 1'), const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(log).position.pixels, greaterThan(0));
    expect(tester.getRect(find.byType(SessionDetailSheet)).top, sheetTop);
  });

  testWidgets('the sheet has a close button that dismisses it', (tester) async {
    await openSessionSheet(tester, _twoPhaseSession(routine));

    expect(find.byType(SessionDetailSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(SessionDetailSheet), findsNothing);
  });

  testWidgets('a phase renamed after the session keeps its recorded kind', (tester) async {
    // The phase ran as a focus phase. It has since been renamed to
    // 'Short Break' - a name that would infer as rest - but the session
    // keeps the kind it was recorded with.
    final session = SessionRecord(
      sessionId: 's_test_5',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
      events: [
        SessionEventRecord(
          eventId: 'e1',
          sessionId: 's_test_5',
          eventType: 'phase_finished',
          occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
          phaseId: 'p1',
          phaseName: 'Short Break',
          durationMs: 25 * 60 * 1000,
          outcome: 'finished',
          kind: PhaseKind.focus,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Rest'), findsNothing);
  });

  testWidgets('a long phase log scrolls instead of overflowing', (tester) async {
    // A routine set to repeat forever grows a phase entry per occurrence, so
    // the log can be long enough to run past the bottom of the sheet.
    final session = SessionRecord(
      sessionId: 's_test_6',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 12, 0),
      totalDurationMs: 120 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
      events: List.generate(
        30,
        (i) => SessionEventRecord(
          eventId: 'e$i',
          sessionId: 's_test_6',
          eventType: 'phase_finished',
          occurredAtUtc:
              DateTime.utc(2026, 10, 16, 10, 0).add(Duration(minutes: 10 * i)),
          phaseId: 'p$i',
          phaseName: 'Sprint ${i + 1}',
          durationMs: 10 * 60 * 1000,
          outcome: 'finished',
          kind: i.isEven ? PhaseKind.focus : PhaseKind.rest,
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sprint 1'), findsOneWidget);
  });

  testWidgets('Tapping Delete Session opens confirmation dialog', (tester) async {
    final session = SessionRecord(
      sessionId: 's_test_3',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SessionDetailSheet(session: session),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete Session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Session Record?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Session Record?'), findsNothing);
  });
}

/// A session of one focus phase and one rest phase.
SessionRecord _twoPhaseSession(Routine routine) {
  return SessionRecord(
    sessionId: 's_sheet_1',
    routineName: 'Deep Focus',
    startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
    endedAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
    totalDurationMs: 30 * 60 * 1000,
    outcome: SessionOutcome.completed,
    routineSnapshot: routine,
    events: [
      SessionEventRecord(
        eventId: 'e1',
        sessionId: 's_sheet_1',
        eventType: 'phase_finished',
        occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
        phaseId: 'p1',
        phaseName: 'Sprint',
        durationMs: 25 * 60 * 1000,
        outcome: 'finished',
        kind: PhaseKind.focus,
      ),
      SessionEventRecord(
        eventId: 'e2',
        sessionId: 's_sheet_1',
        eventType: 'phase_finished',
        occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
        phaseId: 'p2',
        phaseName: 'Break',
        durationMs: 5 * 60 * 1000,
        outcome: 'finished',
        kind: PhaseKind.rest,
      ),
    ],
  );
}

/// A session of thirty phases, so that its phase log is longer than the
/// space the sheet has for it.
SessionRecord _longLogSession(Routine routine) {
  return SessionRecord(
    sessionId: 's_sheet_2',
    routineName: 'Deep Focus',
    startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
    endedAtUtc: DateTime.utc(2026, 10, 16, 12, 0),
    totalDurationMs: 120 * 60 * 1000,
    outcome: SessionOutcome.completed,
    routineSnapshot: routine,
    events: List.generate(
      30,
      (i) => SessionEventRecord(
        eventId: 'e$i',
        sessionId: 's_sheet_2',
        eventType: 'phase_finished',
        occurredAtUtc:
            DateTime.utc(2026, 10, 16, 10, 0).add(Duration(minutes: 10 * i)),
        phaseId: 'p$i',
        phaseName: 'Sprint ${i + 1}',
        durationMs: 10 * 60 * 1000,
        outcome: 'finished',
        kind: i.isEven ? PhaseKind.focus : PhaseKind.rest,
      ),
    ),
  );
}

/// Opens the session sheet the way the history feed opens it: as a modal
/// bottom sheet, so that dragging it and closing it behave as they do in the
/// app.
Future<void> openSessionSheet(
  WidgetTester tester,
  SessionRecord session,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SessionDetailSheet(session: session),
                ),
                child: const Text('Open session'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open session'));
  await tester.pumpAndSettle();
}
