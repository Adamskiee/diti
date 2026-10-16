import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/di/database_provider.dart';
import 'package:focus_flow/src/core/di/notification_providers.dart';
import 'package:focus_flow/src/core/di/repositories_provider.dart';
import 'package:focus_flow/src/core/di/timer_engine_provider.dart';
import 'package:focus_flow/src/core/navigation/app_shell.dart';
import 'package:focus_flow/src/features/history/presentation/widgets/session_detail_sheet.dart';
import 'package:focus_flow/src/features/history/providers/history_providers.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:timer_engine/timer_engine.dart';
import '../helpers/test_fakes.dart';

void main() {
  testWidgets(
      'End-to-End: Start routine, record session, and verify in History and Analytics',
      (tester) async {
    final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 10, 0));
    final fakeClient = FakeNotificationClient();
    final db = createInMemoryTestDatabase();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monotonicClockProvider.overrideWithValue(fakeClock),
        wallClockProvider.overrideWithValue(fakeClock),
        notificationClientProvider.overrideWithValue(fakeClient),
      ],
    );

    final routineRepo = container.read(routineRepositoryProvider);
    final sessionRepo = container.read(sessionRepositoryProvider);

    // Seed a routine
    const routine = Routine(
      id: 'e2e_routine',
      name: 'Flow Focus',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [
        RoutinePhase(
          id: 'p1',
          name: 'Focus Sprint',
          durationMs: 25 * 60 * 1000,
          transition: TransitionPolicy.manual,
        ),
      ],
    );
    await routineRepo.saveRoutine(routine);

    // Record a completed session
    final session = SessionRecord(
      sessionId: 'session_e2e_1',
      routineId: 'e2e_routine',
      routineName: 'Flow Focus',
      startedAtUtc: fakeClock.utcNow,
      endedAtUtc: fakeClock.utcNow.add(const Duration(minutes: 25)),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
    );
    await sessionRepo.recordSession(session);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Switch to History & Analytics tab (Tab 2)
    final historyTabFinder = find.byIcon(Icons.history).evaluate().isNotEmpty
        ? find.byIcon(Icons.history)
        : find.byIcon(Icons.history_outlined);
    await tester.tap(historyTabFinder);
    await tester.pumpAndSettle();

    // Verify Analytics view loaded with metrics
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Focus Activity'), findsOneWidget);
    expect(find.text('Total Focus'), findsOneWidget);

    // Switch to History feed
    final historySegmentFinder = find.descendant(
      of: find.byType(SegmentedButton<HistoryTab>),
      matching: find.text('History'),
    );
    await tester.tap(historySegmentFinder);
    await tester.pumpAndSettle();

    // Verify session tile is displayed
    expect(find.text('Flow Focus'), findsOneWidget);

    // Tap tile to open SessionDetailSheet
    await tester.tap(find.text('Flow Focus'));
    await tester.pumpAndSettle();

    expect(find.byType(SessionDetailSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SessionDetailSheet),
        matching: find.text('Completed'),
      ),
      findsOneWidget,
    );
    expect(find.text('Delete Session'), findsOneWidget);

    await db.close();
    container.dispose();
  });
}
