import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/navigation/app_shell.dart';
import 'package:diti/src/features/history/presentation/widgets/session_feed_tile.dart';
import 'package:diti/src/features/history/presentation/widgets/session_verification_sheet.dart';
import 'package:diti/src/features/history/providers/history_providers.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:timer_engine/timer_engine.dart';
import '../helpers/test_fakes.dart';

void main() {
  testWidgets(
      'E2E: Timer finishes -> SessionVerificationSheet displays -> User edits & saves -> Appears in History & Analytics',
      (tester) async {
    final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 20, 10, 0));
    final db = createInMemoryTestDatabase();
    final fakeClient = FakeNotificationClient();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monotonicClockProvider.overrideWithValue(fakeClock),
        wallClockProvider.overrideWithValue(fakeClock),
        notificationClientProvider.overrideWithValue(fakeClient),
      ],
    );

    final routineRepo = container.read(routineRepositoryProvider);
    const testRoutine = Routine(
      id: 'e2e-routine',
      name: 'Sprint Task',
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
    await routineRepo.saveRoutine(testRoutine);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Start routine
    final startRes = await container
        .read(activeTimerControllerProvider.notifier)
        .startRoutine('e2e-routine');
    expect(startRes.success, isTrue);

    // 2. Advance time and finish run
    fakeClock.advance(const Duration(minutes: 25));
    final finishRes = await container
        .read(activeTimerControllerProvider.notifier)
        .finishRun();
    expect(finishRes.success, isTrue);
    await tester.pumpAndSettle();

    // 3. Verify SessionVerificationSheet is presented
    expect(find.byType(SessionVerificationSheet), findsOneWidget);
    expect(find.text('Verify Focus Session'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    // 4. Edit title and adjust duration
    await tester.enterText(find.byType(TextFormField), 'Verified Sprint');
    await tester.tap(find.text('+5m'));
    await tester.pumpAndSettle();
    expect(find.text('30:00'), findsOneWidget);

    // 5. Tap Save to Analytics
    await tester.tap(find.text('Save to Analytics'));
    await tester.pumpAndSettle();

    // 6. Verify sheet is dismissed
    expect(find.byType(SessionVerificationSheet), findsNothing);

    // 7. Switch to History & Analytics tab (defaults to Analytics tab)
    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    // 8. Verify the verified session is aggregated into Analytics view
    expect(find.text('Total Focus'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);

    // Switch to History tab in SegmentedButton
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<HistoryTab>),
        matching: find.text('History'),
      ),
    );
    await tester.pumpAndSettle();

    // 9. Verify the updated session appears in History with verified name and duration
    expect(find.byType(SessionFeedTile), findsOneWidget);
    expect(find.text('Verified Sprint'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);

    await db.close();
    container.dispose();
  });
}
