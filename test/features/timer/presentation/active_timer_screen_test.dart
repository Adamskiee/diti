import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:diti/src/features/timer/presentation/active_timer_screen.dart';
import 'package:diti/src/features/timer/presentation/widgets/circular_timer_dial.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti/src/features/history/providers/history_providers.dart';
import '../../../../test/helpers/test_fakes.dart';

void main() {
  group('ActiveTimerScreen', () {
    testWidgets(
        'renders countdown, pause button, and handles stop dialog confirmation',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r1',
        name: 'Pomodoro',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
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
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Focus'), findsWidgets); // Title and chip/phase info
      expect(find.text('Focusing'), findsOneWidget);

      // Tap pause
      final pauseButton = find.byKey(const Key('timer_play_pause_button'));
      expect(pauseButton, findsOneWidget);
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(container.read(activeTimerControllerProvider).status,
          RunStatus.paused);

      // Tap stop
      final stopButton = find.byKey(const Key('timer_stop_button'));
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      expect(container.read(activeTimerControllerProvider).status,
          RunStatus.cancelled);

      container.dispose();
      await db.close();
    });

    testWidgets('tapping stop button cancels the active run', (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_dismiss',
        name: 'Pomodoro',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
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
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r_dismiss');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap stop
      await tester.tap(find.byKey(const Key('timer_stop_button')));
      await tester.pumpAndSettle();

      expect(container.read(activeTimerControllerProvider).status,
          RunStatus.cancelled);

      container.dispose();
      await db.close();
    });

    testWidgets(
        'stopping active timer with elapsed time triggers session verification',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_stop_verify',
        name: 'Sprint Focus',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
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
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r_stop_verify');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Advance clock by 15 seconds
      fakeClock.advance(const Duration(seconds: 15));
      await tester.pump();

      // Tap stop
      await tester.tap(find.byKey(const Key('timer_stop_button')));
      await tester.pumpAndSettle();

      final verificationState =
          container.read(sessionVerificationControllerProvider);
      expect(verificationState.isVisible, isTrue);
      expect(verificationState.draftRoutineName, equals('Sprint Focus'));
      expect(verificationState.draftDurationMs, equals(15000));
      expect(verificationState.candidateSession?.outcome,
          equals(SessionOutcome.completed));

      container.dispose();
      await db.close();
    });

    testWidgets('resumes from pause, skips phase, and finishes phase',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_multi',
        name: 'Intervals',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Phase One',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'p2',
            name: 'Phase Two',
            durationMs: 30000,
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
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r_multi');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pause
      final playPauseButton = find.byKey(const Key('timer_play_pause_button'));
      await tester.tap(playPauseButton);
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsOneWidget);

      // Resume
      await tester.tap(playPauseButton);
      await tester.pumpAndSettle();
      expect(find.text('PAUSED'), findsNothing);
      expect(container.read(activeTimerControllerProvider).status,
          RunStatus.running);

      // Skip phase -> transitions to Phase Two
      final skipButton = find.byTooltip('Skip Phase');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(find.text('Phase Two'), findsWidgets);

      // Finish phase -> since Phase Two was the last phase in count 1, routine completes
      final finishButton = find.byTooltip('Finish Phase');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      expect(container.read(activeTimerControllerProvider).status,
          RunStatus.completed);
      expect(find.text('Routine Complete! Great work.'), findsOneWidget);
      expect(find.byKey(const Key('timer_done_button')), findsOneWidget);
      expect(find.byKey(const Key('timer_stop_button')), findsNothing);

      // Tap Done button
      await tester.tap(find.byKey(const Key('timer_done_button')));
      await tester.pumpAndSettle();

      container.dispose();
      await db.close();
    });

    testWidgets('renders awaitingAction state with prominent Start Next Phase',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_manual',
        name: 'Manual Transition',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Phase A',
            durationMs: 10000,
            transition: TransitionPolicy.manual,
          ),
          RoutinePhase(
            id: 'p2',
            name: 'Phase B',
            durationMs: 10000,
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
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_manual');

      // Advance clock by 10s so phase A completes and awaits manual action
      fakeClock.advance(const Duration(seconds: 10));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      controller.tick();

      expect(container.read(activeTimerControllerProvider).isAwaitingAction,
          isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED — READY TO CONTINUE'), findsOneWidget);
      expect(find.text('Start Next Phase'), findsOneWidget);

      // Tap 'Start Next Phase'
      await tester.tap(find.text('Start Next Phase'));
      await tester.pumpAndSettle();

      expect(find.text('Phase B'), findsWidgets);
      expect(container.read(activeTimerControllerProvider).isAwaitingAction,
          isFalse);

      container.dispose();
      await db.close();
    });

    testWidgets(
        'renders overtime state with negative timer and OVERTIME badge for rest phase',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_overtime_rest',
        name: 'Overtime Rest Test',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p_rest',
            name: 'Break',
            durationMs: 10000, // 10s
            transition: TransitionPolicy.manual,
            kind: PhaseKind.rest,
          ),
          RoutinePhase(
            id: 'p_focus',
            name: 'Focus',
            durationMs: 10000,
            transition: TransitionPolicy.auto,
            kind: PhaseKind.focus,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_overtime_rest');

      // Advance clock by 15s (5s overtime)
      fakeClock.advance(const Duration(seconds: 15));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      controller.tick();

      expect(container.read(activeTimerControllerProvider).isAwaitingAction,
          isTrue);
      expect(container.read(activeTimerControllerProvider).displayRemainingMs,
          equals(-5000));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-00:05'), findsOneWidget);
      expect(find.text('OVERTIME — READY TO CONTINUE'), findsOneWidget);
      expect(find.text('Start Next Phase'), findsOneWidget);

      container.dispose();
      await db.close();
    });

    testWidgets('renders open-ended phase with Open Flow badge',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_open',
        name: 'Open Flow Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Free Flow',
            durationMs: null,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r_open');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Flow'), findsWidgets);
      expect(find.text('Open Flow'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CircularTimerDial),
          matching: find.text('00:00'),
        ),
        findsOneWidget,
      );

      container.dispose();
      await db.close();
    });

    testWidgets(
        'renders session summary card with total, focus, and rest durations',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_summary',
        name: 'Summary Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            kind: PhaseKind.focus,
            durationMs: 1500000,
            transition: TransitionPolicy.manual,
          ),
          RoutinePhase(
            id: 'p2',
            name: 'Rest',
            kind: PhaseKind.rest,
            durationMs: 300000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_summary');

      // Advance 120s in Focus phase
      fakeClock.advance(const Duration(seconds: 120));
      controller.tick();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ActiveTimerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryCard = find.byKey(const Key('session_summary_card'));
      expect(summaryCard, findsOneWidget);
      expect(find.text('Session Summary'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Focus'),
          findsWidgets); // header chip/phase + summary label
      expect(find.text('Rest'), findsOneWidget);

      // Total: 02:00, Focus: 02:00, Rest: 00:00
      expect(find.text('02:00'), findsWidgets);
      expect(find.text('00:00'), findsOneWidget);

      // Now switch to Rest phase and advance 60s
      await controller.finishPhase();
      fakeClock.advance(const Duration(seconds: 60));
      controller.tick();
      await tester.pumpAndSettle();

      // Total: 03:00, Focus: 02:00, Rest: 01:00
      expect(find.text('03:00'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);

      container.dispose();
      await db.close();
    });

    testWidgets('Minimize button closes ActiveTimerScreen when pushed',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_close',
        name: 'Close Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            durationMs: 1500000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r_close');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActiveTimerScreen(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ActiveTimerScreen), findsOneWidget);

      // Tap Minimize button
      final minimizeButton = find.byKey(const Key('timer_minimize_button'));
      expect(minimizeButton, findsOneWidget);
      await tester.tap(minimizeButton);
      await tester.pumpAndSettle();

      expect(find.byType(ActiveTimerScreen), findsNothing);

      container.dispose();
      await db.close();
    });
  });
}
