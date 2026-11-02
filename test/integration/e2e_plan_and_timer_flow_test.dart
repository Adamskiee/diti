import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/navigation/app_shell.dart';
import 'package:diti/src/features/history/presentation/widgets/session_verification_sheet.dart';
import 'package:diti/src/features/plan/presentation/widgets/plan_block_card.dart';
import 'package:diti/src/features/plan/providers/plan_providers.dart';
import 'package:diti/src/features/routines/data/starter_routines.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import '../helpers/test_fakes.dart';

void main() {
  testWidgets(
      'E2E: Schedule block, start block, complete timer, verify actual duration in plan',
      (tester) async {
    final db = createInMemoryTestDatabase();
    final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
    final fakeClient = FakeNotificationClient();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monotonicClockProvider.overrideWithValue(fakeClock),
        wallClockProvider.overrideWithValue(fakeClock),
        notificationClientProvider.overrideWithValue(fakeClient),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
      ],
    );

    // 1. Seed routines
    final routineRepo = container.read(routineRepositoryProvider);
    await seedStarterRoutines(routineRepo);

    // Seed a future scheduled block to verify it remains unaltered
    final planRepo = container.read(planBlockRepositoryProvider);
    await planRepo.createPlanBlock(
      PlanBlock(
        id: 'future-block-deep-work',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 3600000,
        routineId: 'Deep Work',
        status: PlanBlockStatus.scheduled,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Navigate to Daily Plan tab
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Daily Plan'), findsOneWidget);
    // Future block is present, so "Deep Work" should be visible
    expect(find.text('Deep Work'), findsOneWidget);

    // 3. Schedule a block via FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Schedule Block'), findsOneWidget);
    await tester.tap(find.text('Save Block'));
    await tester.pumpAndSettle();

    // 4. Block appears in list as Scheduled
    expect(find.text('Classic Pomodoro'), findsOneWidget);
    expect(find.text('Scheduled'), findsNWidgets(2)); // Pomodoro and Deep Work

    // 5. Tap "Start Block" on Classic Pomodoro
    final pomodoroCard = find.ancestor(
      of: find.text('Classic Pomodoro'),
      matching: find.byType(PlanBlockCard),
    );
    final startButton = find.descendant(
      of: pomodoroCard,
      matching: find.widgetWithText(FilledButton, 'Start Block'),
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Verify block in SQLite transitioned to inProgress
    final inProgressBlocks = await container
        .read(planBlockRepositoryProvider)
        .getBlocksForDate('2026-10-16');
    final inProgressPomodoro =
        inProgressBlocks.firstWhere((b) => b.routineId == 'Classic Pomodoro');
    expect(inProgressPomodoro.status, PlanBlockStatus.inProgress);

    // 6. ActiveTimerScreen is open
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    // 7. Advance fake clock into focus phase and finish run
    fakeClock.advance(const Duration(minutes: 24));
    container.read(activeTimerControllerProvider.notifier).tick();
    await tester.pump();

    // Finish session early / complete run
    await container.read(activeTimerControllerProvider.notifier).finishRun();
    await tester.pumpAndSettle();

    // Verification sheet is presented; adjust duration to 25m and tap "Save to Analytics"
    expect(find.byType(SessionVerificationSheet), findsOneWidget);
    await tester.tap(find.text('+1m'));
    await tester.pumpAndSettle();
    expect(totalDurationText(tester), '25:00');
    await tester.tap(find.text('Save to Analytics'));
    await tester.pumpAndSettle();

    // Tap Done on completion screen
    expect(find.byKey(const Key('timer_done_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('timer_done_button')));
    await tester.pumpAndSettle();

    // 8. Back on Daily Plan screen: block is Completed with actual duration
    expect(find.text('Completed'), findsOneWidget);
    final blocks = await container
        .read(planBlockRepositoryProvider)
        .getBlocksForDate('2026-10-16');
    final completedBlock =
        blocks.firstWhere((b) => b.routineId == 'Classic Pomodoro');
    expect(completedBlock.status, PlanBlockStatus.completed);
    expect(completedBlock.sessionId, isNotNull);
    expect(completedBlock.actualDurationMs, isNotNull);

    // 9. Verify future scheduled blocks remain unaltered
    final futureBlock =
        blocks.firstWhere((b) => b.id == 'future-block-deep-work');
    expect(futureBlock.status, PlanBlockStatus.scheduled);
    expect(futureBlock.sessionId, isNull);
    expect(futureBlock.actualDurationMs, isNull);

    await db.close();
    container.dispose();
  });
}

/// The number on the sheet's duration card — the session's total time.
String totalDurationText(WidgetTester tester) {
  final text =
      tester.widget<Text>(find.byKey(const Key('total_duration_value')));
  return text.data ?? '';
}
