import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:diti/src/core/di/app_info_providers.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/navigation/app_shell.dart';
import 'package:diti/src/features/history/presentation/history_analytics_screen.dart';
import 'package:diti/src/features/plan/presentation/plan_screen.dart';
import 'package:diti/src/features/routines/presentation/routine_editor_screen.dart';
import 'package:diti/src/features/settings/presentation/settings_screen.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:diti/src/features/timer/presentation/active_timer_screen.dart';
import 'package:diti/src/features/timer/presentation/widgets/active_timer_mini_player.dart';
import 'package:diti_notifications/diti_notifications.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../helpers/test_fakes.dart';

class FakeCoordinator implements TimerLifecycleCoordinator {
  int initializeCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> onPause() async {
    pauseCalls++;
  }

  @override
  Future<void> onResume() async {
    resumeCalls++;
  }

  @override
  void dispose() {
    disposeCalls++;
  }
}

void main() {
  group('AppShell & Navigation Tests', () {
    testWidgets(
        'AppShell switches tabs, renders placeholders, and renders SettingsScreen',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final fakePermission = FakePermissionService();
      final fakeCoordinator = FakeCoordinator();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          notificationPermissionServiceProvider
              .overrideWithValue(fakePermission),
          timerLifecycleCoordinatorProvider.overrideWithValue(fakeCoordinator),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
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

      // Coordinator initialize() called on startup
      expect(fakeCoordinator.initializeCalls, 1);

      // Default tab is Routines
      expect(find.text('Routines'), findsWidgets);
      expect(find.byType(ActiveTimerMiniPlayer), findsNothing);

      // Switch to Plan tab
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(PlanScreen), findsOneWidget);
      expect(find.textContaining('No blocks scheduled for this day'),
          findsOneWidget);

      // Switch to History tab
      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryAnalyticsScreen), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HistoryAnalyticsScreen),
          matching: find.text('History'),
        ),
        findsOneWidget,
      );

      // Switch to Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Settings & Diagnostics'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('2.2.0'), findsOneWidget);
      expect(find.text('Notifications: '), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Exact Alarms: '), findsOneWidget);
      expect(find.text('Allowed'), findsOneWidget);

      // Switch back to Routines tab
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();

      expect(
          find.text('No routines found. Tap + to create one!'), findsOneWidget);

      await db.close();
      container.dispose();
    });

    testWidgets(
        'AppShell responds to lifecycle events via WidgetsBindingObserver',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final fakeCoordinator = FakeCoordinator();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerLifecycleCoordinatorProvider.overrideWithValue(fakeCoordinator),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
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
      expect(fakeCoordinator.initializeCalls, 1);

      // Simulate app pausing
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(fakeCoordinator.pauseCalls, 1);

      // Simulate app hidden
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      expect(fakeCoordinator.pauseCalls, 2);

      // Simulate app resuming
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(fakeCoordinator.resumeCalls, 1);

      await db.close();
      container.dispose();
    });

    testWidgets('AppShell shows ActiveTimerMiniPlayer when timer is active',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final fakeCoordinator = FakeCoordinator();
      const testRoutine = Routine(
        id: 'r-1',
        name: 'Work Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p-1',
            name: 'Focus',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerLifecycleCoordinatorProvider.overrideWithValue(fakeCoordinator),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ActiveTimerMiniPlayer), findsNothing);

      // Start the timer via activeTimerControllerProvider
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r-1');
      await tester.pumpAndSettle();

      // Mini player is now visible in AppShell bottomNavigationBar
      expect(find.byType(ActiveTimerMiniPlayer), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);

      await db.close();
      container.dispose();
    });

    testWidgets('AppShell navigates to RoutineEditorScreen on add/edit',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final fakeCoordinator = FakeCoordinator();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerLifecycleCoordinatorProvider.overrideWithValue(fakeCoordinator),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
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

      // Tap the + FAB to add routine
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // RoutineEditorScreen should be pushed
      expect(find.byType(RoutineEditorScreen), findsOneWidget);
      expect(find.text('New Routine'), findsOneWidget);

      await db.close();
      container.dispose();
    });

    testWidgets(
        'AppShell starts routine and opens ActiveTimerScreen onStartRoutine',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final fakeCoordinator = FakeCoordinator();

      // Seed a routine
      const testRoutine = Routine(
        id: 'r-start',
        name: 'Deep Work',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p-start',
            name: 'Coding',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerLifecycleCoordinatorProvider.overrideWithValue(fakeCoordinator),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the play button on the routine card
      expect(find.text('Deep Work'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // ActiveTimerScreen should be opened
      expect(find.byType(ActiveTimerScreen), findsOneWidget);
      expect(find.text('Coding'), findsWidgets);

      await db.close();
      container.dispose();
    });

    testWidgets('AppShell shows SnackBar if startRoutine fails',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final fakeCoordinator = FakeCoordinator();

      const testRoutine = Routine(
        id: 'r-fail',
        name: 'Empty Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerLifecycleCoordinatorProvider.overrideWithValue(fakeCoordinator),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(ActiveTimerScreen), findsNothing);

      await db.close();
      container.dispose();
    });
  });
}
