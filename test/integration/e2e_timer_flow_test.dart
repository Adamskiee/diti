import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/main.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/navigation/app_shell.dart';
import 'package:diti/src/features/history/presentation/widgets/session_verification_sheet.dart';
import 'package:diti/src/features/routines/data/starter_routines.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:timer_engine/timer_engine.dart';
import '../helpers/test_fakes.dart';

void main() {
  group('DitiApp & E2E Timer Flow Integration Tests', () {
    testWidgets(
        'DitiApp bootstraps routines, initializes notifications, and renders AppShell',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 10, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DitiApp(),
        ),
      );

      // Verify that after bootstrap settles, the main screen is rendered with seeded routines
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Classic Pomodoro'), findsOneWidget);
      expect(find.text('Deep Work'), findsOneWidget);
      expect(find.text('Open Flow'), findsOneWidget);
      expect(fakeClient.isInitialized, isTrue);
      expect(fakeClient.initializationSettings, isNotNull);

      await db.close();
      container.dispose();
    });

    testWidgets(
        'E2E: Start seeded Pomodoro, tick, pause, minimize, switch tabs, cancel',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 10, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      // Seed starter routines
      final repo = container.read(routineRepositoryProvider);
      await seedStarterRoutines(repo);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify seeded Pomodoro exists
      expect(find.text('Classic Pomodoro'), findsOneWidget);

      // 2. Start Pomodoro routine
      final startButton = find.text('Start').first;
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // 3. Verify ActiveTimerScreen opened at 25:00
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);

      // 4. Advance fake clock by 5 minutes and tick
      fakeClock.advance(const Duration(minutes: 5));
      container.read(activeTimerControllerProvider.notifier).tick();
      await tester.pump();
      expect(find.text('20:00'), findsOneWidget);

      // 5. Pause timer
      final pauseButton = find.byKey(const Key('timer_play_pause_button'));
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      // 6. Minimize timer screen to reveal mini-player
      final minimizeButton = find.byTooltip('Minimize');
      await tester.tap(minimizeButton);
      await tester.pumpAndSettle();

      // 7. Verify mini-player is visible on the bottom
      expect(find.byKey(const Key('mini_player_toggle_button')), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);

      // 8. Switch to Settings tab
      final settingsFinder = find.byIcon(Icons.settings).evaluate().isNotEmpty
          ? find.byIcon(Icons.settings)
          : find.byIcon(Icons.settings_outlined);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      // Verify mini-player persists across tabs
      expect(find.text('Settings & Diagnostics'), findsOneWidget);
      expect(find.byKey(const Key('mini_player_toggle_button')), findsOneWidget);

      // 9. Stop timer
      await container.read(activeTimerControllerProvider.notifier).stop();
      await tester.pumpAndSettle();

      // Verify SessionVerificationSheet is presented and dismiss by saving
      expect(find.byType(SessionVerificationSheet), findsOneWidget);
      await tester.tap(find.text('Save to Analytics'));
      await tester.pumpAndSettle();

      // Verify mini-player dismisses
      expect(find.byKey(const Key('mini_player_toggle_button')), findsNothing);

      await db.close();
      container.dispose();
    });
  });
}
