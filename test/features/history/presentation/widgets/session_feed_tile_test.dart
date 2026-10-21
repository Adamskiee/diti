import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/presentation/widgets/session_feed_tile.dart';
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

  testWidgets('SessionFeedTile renders routine name, duration and responds to tap', (tester) async {
    var tapped = false;
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
      MaterialApp(
        home: Scaffold(
          body: SessionFeedTile(
            session: session,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Deep Focus'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await tester.tap(find.byType(SessionFeedTile));
    expect(tapped, isTrue);
  });

  testWidgets('SessionFeedTile renders Quick Timer fallback and cancel icon', (tester) async {
    final session = SessionRecord(
      sessionId: 's_test_2',
      routineName: '',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 10),
      totalDurationMs: 10 * 60 * 1000,
      outcome: SessionOutcome.cancelled,
      routineSnapshot: routine,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionFeedTile(
            session: session,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Quick Timer'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('shows the focus and rest split', (tester) async {
    final session = SessionRecord(
      sessionId: 's_test_3',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
      totalDurationMs: 30 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
      events: [
        SessionEventRecord(
          eventId: 'e1',
          sessionId: 's_test_3',
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
          sessionId: 's_test_3',
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
      MaterialApp(
        home: Scaffold(
          body: SessionFeedTile(
            session: session,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('30:00'), findsOneWidget);
    expect(find.textContaining('25:00 focus'), findsOneWidget);
    expect(find.textContaining('05:00 rest'), findsOneWidget);
  });

  testWidgets('a session with no breakdown shows only the total', (tester) async {
    // A session recorded before the per-phase breakdown existed has no
    // events, so it shows its total alone - there is no empty split.
    final session = SessionRecord(
      sessionId: 's_test_4',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 25),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionFeedTile(
            session: session,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('25:00'), findsOneWidget);
    expect(find.textContaining('focus'), findsNothing);
    expect(find.textContaining('rest'), findsNothing);
  });

  testWidgets('a phase renamed after the session keeps its recorded kind', (tester) async {
    // 'Short Break' was recorded as a focus phase, so it counts towards the
    // focus time even though its name would infer as rest.
    final session = SessionRecord(
      sessionId: 's_test_5',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
      totalDurationMs: 30 * 60 * 1000,
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
        SessionEventRecord(
          eventId: 'e2',
          sessionId: 's_test_5',
          eventType: 'phase_finished',
          occurredAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
          phaseId: 'p2',
          phaseName: 'Long Rest',
          durationMs: 5 * 60 * 1000,
          outcome: 'finished',
          kind: PhaseKind.rest,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionFeedTile(
            session: session,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('25:00 focus'), findsOneWidget);
    expect(find.textContaining('05:00 rest'), findsOneWidget);
  });

  testWidgets('lays out without overflowing on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final session = SessionRecord(
      sessionId: 's_test_6',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 30),
      totalDurationMs: 30 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
      events: [
        SessionEventRecord(
          eventId: 'e1',
          sessionId: 's_test_6',
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
          sessionId: 's_test_6',
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
      MaterialApp(
        home: Scaffold(
          body: SessionFeedTile(
            session: session,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // The split must not take the width the routine name needs: the name
    // keeps a readable width on a narrow screen.
    expect(tester.getSize(find.text('Deep Focus')).width, greaterThan(100));
  });
}
