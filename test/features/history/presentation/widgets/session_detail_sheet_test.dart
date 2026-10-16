import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
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
