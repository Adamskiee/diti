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
