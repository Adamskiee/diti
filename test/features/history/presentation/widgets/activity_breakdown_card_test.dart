import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/presentation/widgets/activity_breakdown_card.dart';
import 'package:diti/src/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';

void main() {
  const mockRoutine = Routine(
    id: 'r1',
    name: 'Deep Work',
    repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
    phases: [
      RoutinePhase(
        id: 'p1',
        name: 'Focus',
        durationMs: 45 * 60 * 1000,
        transition: TransitionPolicy.auto,
      ),
    ],
  );

  testWidgets('ActivityBreakdownCard renders nothing when breakdowns is empty',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActivityBreakdownCard(breakdowns: []),
        ),
      ),
    );

    expect(find.text('Activity Breakdown'), findsNothing);
  });

  testWidgets('ActivityBreakdownCard renders breakdown items and percentages',
      (tester) async {
    final breakdowns = [
      const ActivityBreakdown(
        routineName: 'Deep Work',
        totalDurationMs: 3600000,
        percentage: 0.75,
        color: Colors.blue,
      ),
      const ActivityBreakdown(
        routineName: 'Reading',
        totalDurationMs: 1200000,
        percentage: 0.25,
        color: Colors.orange,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityBreakdownCard(breakdowns: breakdowns),
        ),
      ),
    );

    expect(find.text('Activity Breakdown'), findsOneWidget);
    expect(find.textContaining('Deep Work (75% · 01:00:00)'), findsOneWidget);
    expect(find.textContaining('Reading (25% · 20:00)'), findsOneWidget);
  });

  testWidgets(
      'ActivityBreakdownCard displays session count and expands to reveal sessions',
      (tester) async {
    final session1 = SessionRecord(
      sessionId: 's1',
      routineName: 'Deep Work',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 45),
      totalDurationMs: 45 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: mockRoutine,
    );
    final session2 = SessionRecord(
      sessionId: 's2',
      routineName: 'Deep Work',
      startedAtUtc: DateTime.utc(2026, 10, 16, 14, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 14, 30),
      totalDurationMs: 30 * 60 * 1000,
      outcome: SessionOutcome.cancelled,
      routineSnapshot: mockRoutine,
    );

    final breakdowns = [
      ActivityBreakdown(
        routineName: 'Deep Work',
        totalDurationMs: 75 * 60 * 1000,
        percentage: 1.0,
        color: Colors.blue,
        sessions: [session1, session2],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityBreakdownCard(breakdowns: breakdowns),
        ),
      ),
    );

    // Shows routine title and session count
    expect(find.textContaining('Deep Work (100% · 01:15:00)'), findsOneWidget);
    expect(find.text('2 sessions'), findsOneWidget);

    // Before expanding, individual sessions are not visible
    expect(find.text('45:00'), findsNothing);
    expect(find.text('30:00'), findsNothing);

    // Tap to expand
    await tester.tap(find.textContaining('Deep Work'));
    await tester.pumpAndSettle();

    // After expanding, session details and durations appear
    expect(find.text('45:00'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });

  testWidgets('Tapping an expanded session opens SessionDetailSheet',
      (tester) async {
    final session = SessionRecord(
      sessionId: 's_tap_1',
      routineName: 'Deep Work',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 45),
      totalDurationMs: 45 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: mockRoutine,
    );

    final breakdowns = [
      ActivityBreakdown(
        routineName: 'Deep Work',
        totalDurationMs: 45 * 60 * 1000,
        percentage: 1.0,
        color: Colors.blue,
        sessions: [session],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ActivityBreakdownCard(breakdowns: breakdowns),
          ),
        ),
      ),
    );

    // Expand the routine
    await tester.tap(find.textContaining('Deep Work'));
    await tester.pumpAndSettle();

    expect(find.text('45:00'), findsOneWidget);

    // Tap the session
    await tester.tap(find.text('45:00'));
    await tester.pumpAndSettle();

    // Verify SessionDetailSheet is presented
    expect(find.byType(SessionDetailSheet), findsOneWidget);
    expect(find.text('Delete Session'), findsOneWidget);
  });
}
