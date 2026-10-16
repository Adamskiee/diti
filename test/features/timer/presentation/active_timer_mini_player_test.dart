import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/di/database_provider.dart';
import 'package:focus_flow/src/core/di/notification_providers.dart';
import 'package:focus_flow/src/core/di/repositories_provider.dart';
import 'package:focus_flow/src/core/di/timer_engine_provider.dart';
import 'package:focus_flow/src/features/timer/controllers/active_timer_controller.dart';
import 'package:focus_flow/src/features/timer/domain/timer_display_state.dart';
import 'package:focus_flow/src/features/timer/presentation/active_timer_screen.dart';
import 'package:focus_flow/src/features/timer/presentation/widgets/active_timer_mini_player.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../../test/helpers/test_fakes.dart';

void main() {
  group('ActiveTimerMiniPlayer', () {
    testWidgets('renders when active, toggles pause/resume, and expands to ActiveTimerScreen',
        (tester) async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r1',
        name: 'Pomodoro',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 2),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            durationMs: 1500000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'p2',
            name: 'Break',
            durationMs: 300000,
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: ActiveTimerMiniPlayer()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Idle -> SizedBox.shrink()
      expect(find.byType(ActiveTimerMiniPlayer), findsOneWidget);
      expect(find.text('Focus'), findsNothing);
      expect(find.byKey(const Key('mini_player_toggle_button')), findsNothing);

      // 2. Start routine -> becomes active
      await container.read(activeTimerControllerProvider.notifier).startRoutine('r1');
      await tester.pumpAndSettle();

      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Repetition 1 · Phase 1'), findsOneWidget);

      // Verify LinearProgressIndicator is present
      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);
      final progressIndicator = tester.widget<LinearProgressIndicator>(progressFinder);
      expect(progressIndicator.value, 1.0);

      // Verify Tabular Figures font feature is set on countdown Text
      final timeFinder = find.text('25:00');
      final timeWidget = tester.widget<Text>(timeFinder);
      expect(timeWidget.style?.fontFeatures, contains(const FontFeature.tabularFigures()));

      // 3. Pause
      final toggle = find.byKey(const Key('mini_player_toggle_button'));
      expect(toggle, findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(container.read(activeTimerControllerProvider).status, RunStatus.paused);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // Tapping toggle button must not trigger route push to ActiveTimerScreen
      expect(find.byType(ActiveTimerScreen), findsNothing);

      // 4. Resume
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(container.read(activeTimerControllerProvider).status, RunStatus.running);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byType(ActiveTimerScreen), findsNothing);

      // 5. Tap mini-player body opens ActiveTimerScreen
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();

      expect(find.byType(ActiveTimerScreen), findsOneWidget);

      container.dispose();
      await db.close();
    });

    testWidgets('renders when awaitingAction and handles empty cycleDescription',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          activeTimerControllerProvider.overrideWith(
            () => _FakeActiveTimerController(
              const TimerDisplayState(
                runId: 'fake-run',
                status: RunStatus.running,
                phaseStatus: PhaseStatus.awaitingAction,
                phaseName: 'Long Rest Phase',
                cycleDescription: '',
                formattedTime: '05:00',
                progress: 0.5,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: ActiveTimerMiniPlayer()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Long Rest Phase'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
      // Since cycleDescription is empty, no second Column Text is rendered
      expect(find.byType(ActiveTimerMiniPlayer), findsOneWidget);

      container.dispose();
    });
  });
}

class _FakeActiveTimerController extends ActiveTimerController {
  final TimerDisplayState _initialState;

  _FakeActiveTimerController(this._initialState);

  @override
  TimerDisplayState build() => _initialState;
}
