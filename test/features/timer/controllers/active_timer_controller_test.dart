import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/di/tracker_provider.dart';
import 'package:diti/src/features/history/providers/history_providers.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:diti/src/features/timer/domain/timer_display_state.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../helpers/test_fakes.dart';

class MockSessionAppTracker extends Mock implements SessionAppTracker {}

void main() {
  group('ActiveTimerController', () {
    test('starts routine, updates display state, and pauses', () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
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
      expect(
          container.read(activeTimerControllerProvider).status, RunStatus.idle);

      await controller.startRoutine('r1');
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.running,
      );
      expect(container.read(activeTimerControllerProvider).phaseName, 'Focus');
      expect(
        container.read(activeTimerControllerProvider).formattedTime,
        '25:00',
      );

      // Advance clock 60s
      fakeClock.advance(const Duration(seconds: 60));
      controller.tick(); // Manual tick trigger in test

      expect(
        container.read(activeTimerControllerProvider).formattedTime,
        '24:00',
      );

      // Pause
      await controller.pause();
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.paused,
      );

      // Stop
      await controller.stop();
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.cancelled,
      );

      container.dispose();
      await db.close();
    });

    test('handles resume, skipPhase, finishPhase, and finishRun', () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r2',
        name: 'Two Phase',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 60000,
            transition: TransitionPolicy.auto,
          ),
          RoutinePhase(
            id: 'p2',
            name: 'Rest',
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

      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r2');

      expect(container.read(activeTimerControllerProvider).phaseName, 'Work');
      expect(
        container.read(activeTimerControllerProvider).nextPhasePreview,
        'Rest',
      );

      // Pause and Resume
      await controller.pause();
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.paused,
      );

      await controller.resume();
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.running,
      );

      // Skip phase to Rest
      await controller.skipPhase();
      expect(container.read(activeTimerControllerProvider).phaseName, 'Rest');
      expect(
        container.read(activeTimerControllerProvider).nextPhasePreview,
        isNull,
      );

      // Finish run
      await controller.finishRun();
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.completed,
      );

      container.dispose();
      await db.close();
    });

    test('handles open-ended phases with elapsed count-up', () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r3',
        name: 'Open Ended',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Flow',
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

      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r3');

      final initial = container.read(activeTimerControllerProvider);
      expect(initial.isCountdown, isFalse);
      expect(initial.formattedTime, '00:00');
      expect(initial.progress, 1.0);

      fakeClock.advance(const Duration(seconds: 125));
      controller.tick();

      final updated = container.read(activeTimerControllerProvider);
      expect(updated.formattedTime, '02:05');
      expect(updated.displayElapsedMs, 125000);

      // Finish phase
      await controller.finishPhase();
      expect(
        container.read(activeTimerControllerProvider).status,
        RunStatus.completed,
      );

      container.dispose();
      await db.close();
    });

    test('no-op commands when idle return failed command result', () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      final controller = container.read(activeTimerControllerProvider.notifier);

      final resPause = await controller.pause();
      expect(resPause.success, isFalse);

      final resResume = await controller.resume();
      expect(resResume.success, isFalse);

      final resSkip = await controller.skipPhase();
      expect(resSkip.success, isFalse);

      final resFinish = await controller.finishPhase();
      expect(resFinish.success, isFalse);

      final resFinishRun = await controller.finishRun();
      expect(resFinishRun.success, isFalse);

      final resStop = await controller.stop();
      expect(resStop.success, isFalse);

      container.dispose();
      await db.close();
    });

    test('TimerDisplayState helper properties', () {
      const idleState = TimerDisplayState();
      expect(idleState.isActive, isFalse);
      expect(idleState.isAwaitingAction, isFalse);

      const runningState = TimerDisplayState(status: RunStatus.running);
      expect(runningState.isActive, true);
      expect(runningState.isAwaitingAction, false);

      const pausedState = TimerDisplayState(status: RunStatus.paused);
      expect(pausedState.isActive, true);
      expect(pausedState.isAwaitingAction, false);

      const awaitingState = TimerDisplayState(
        status: RunStatus.running,
        phaseStatus: PhaseStatus.awaitingAction,
      );
      expect(awaitingState.isActive, true);
      expect(awaitingState.isAwaitingAction, true);

      const completedState = TimerDisplayState(status: RunStatus.completed);
      expect(completedState.isActive, false);

      const cancelledState = TimerDisplayState(status: RunStatus.cancelled);
      expect(cancelledState.isActive, false);
    });

    test(
        'rest timer in awaitingAction with overtime maps to negative displayRemainingMs and formatted time with minus sign',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_rest_overtime',
        name: 'Rest Overtime Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p_rest',
            name: 'Short Break',
            durationMs: 300000, // 5 min
            transition: TransitionPolicy.manual,
            kind: PhaseKind.rest,
          ),
          RoutinePhase(
            id: 'p_work',
            name: 'Focus',
            durationMs: 1500000,
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

      final repo = container.read(routineRepositoryProvider);
      await repo.saveRoutine(testRoutine);

      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_rest_overtime');

      // Advance clock by 5 min + 45 seconds (345 seconds total)
      fakeClock.advance(const Duration(seconds: 345));
      await pumpEventQueue();
      controller.tick();

      final state = container.read(activeTimerControllerProvider);
      expect(state.phaseStatus, equals(PhaseStatus.awaitingAction));
      expect(state.isAwaitingAction, isTrue);
      expect(state.displayRemainingMs, equals(-45000)); // -45 seconds
      expect(state.formattedTime, equals('-00:45'));
      expect(state.progress, equals(0.0));

      container.dispose();
      await db.close();
    });

    test(
        'periodic ticker updates display state automatically without manual tick',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_ticker',
        name: 'Ticker Test',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            durationMs: 60000,
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
      await controller.startRoutine('r_ticker');

      expect(
        container.read(activeTimerControllerProvider).formattedTime,
        '01:00',
      );

      // Advance fake monotonic clock by 2 seconds
      fakeClock.advance(const Duration(seconds: 2));

      // Wait 300ms for real Timer.periodic(250ms) to fire at least once
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(
        container.read(activeTimerControllerProvider).formattedTime,
        '00:58',
      );

      await controller.pause();
      container.dispose();
      await db.close();
    });

    test(
        'initializes with active run state if engine already has an active run',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_existing',
        name: 'Existing Run',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Study',
            durationMs: 120000,
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

      // Start engine directly before reading activeTimerControllerProvider
      final engine = container.read(timerEngineProvider);
      await engine.start('r_existing');

      // Now read activeTimerControllerProvider for the first time
      final displayState = container.read(activeTimerControllerProvider);
      expect(displayState.status, RunStatus.running);
      expect(displayState.phaseName, 'Study');
      expect(displayState.formattedTime, '02:00');

      container.dispose();
      await db.close();
    });

    test(
        'linking planBlockId updates block to inProgress and records actual duration on finish',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      const routine = Routine(
        id: 'r_pomodoro',
        name: 'Pomodoro',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 1500000,
            transition: TransitionPolicy.manual,
          ), // 25 min
        ],
      );
      await container.read(routineRepositoryProvider).saveRoutine(routine);

      final planBlock = PlanBlock(
        id: 'block_001',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1500000,
        routineId: 'r_pomodoro',
      );
      await container
          .read(planBlockRepositoryProvider)
          .createPlanBlock(planBlock);

      final controller = container.read(activeTimerControllerProvider.notifier);

      // Start routine linked to block
      final res =
          await controller.startRoutine('r_pomodoro', planBlockId: 'block_001');
      expect(res.success, isTrue);
      expect(container.read(activeTimerControllerProvider).planBlockId,
          'block_001');

      // Block is inProgress
      var updatedBlock = await container
          .read(planBlockRepositoryProvider)
          .getBlockById('block_001');
      expect(updatedBlock?.status, PlanBlockStatus.inProgress);

      // Advance clock 25 mins and finish phase
      fakeClock.advance(const Duration(minutes: 25));
      await controller.finishPhase();

      await container
          .read(sessionVerificationControllerProvider.notifier)
          .confirmSave();

      // Block is completed with actual duration recorded
      updatedBlock = await container
          .read(planBlockRepositoryProvider)
          .getBlockById('block_001');
      expect(updatedBlock?.status, PlanBlockStatus.completed);
      expect(updatedBlock?.actualDurationMs, 1500000);
      expect(updatedBlock?.sessionId, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      container.dispose();
      await db.close();
    });

    test(
        'cancelling active timer run updates linked planBlock to completed when saved to analytics and records actual duration',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      const routine = Routine(
        id: 'r_cancel',
        name: 'Pomodoro Cancel',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Work',
            durationMs: 1500000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );
      await container.read(routineRepositoryProvider).saveRoutine(routine);

      final planBlock = PlanBlock(
        id: 'block_002',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1500000,
        routineId: 'r_cancel',
      );
      await container
          .read(planBlockRepositoryProvider)
          .createPlanBlock(planBlock);

      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_cancel', planBlockId: 'block_002');

      // Advance clock 10 mins (600000 ms) and stop/cancel
      fakeClock.advance(const Duration(minutes: 10));
      await controller.stop();

      await container
          .read(sessionVerificationControllerProvider.notifier)
          .confirmSave();

      final updatedBlock = await container
          .read(planBlockRepositoryProvider)
          .getBlockById('block_002');
      expect(updatedBlock?.status, PlanBlockStatus.completed);
      expect(updatedBlock?.actualDurationMs, 600000);
      expect(updatedBlock?.sessionId, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      container.dispose();
      await db.close();
    });

    test('startRoutine resolves routine by name when id does not exist',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      const routine = Routine(
        id: 'uuid_custom_123',
        name: 'Classic Pomodoro',
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
      await container.read(routineRepositoryProvider).saveRoutine(routine);

      final controller = container.read(activeTimerControllerProvider.notifier);
      final res = await controller.startRoutine('Classic Pomodoro');
      expect(res.success, isTrue);

      final state = container.read(activeTimerControllerProvider);
      expect(state.phaseName, 'Focus');
      expect(state.status, RunStatus.running);

      container.dispose();
      await db.close();
    });

    test(
        'startRoutine creates and persists custom routine for unknown custom activity and links plan block',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      final planBlock = PlanBlock(
        id: 'block_custom',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000, // 30 min
        routineId: 'Team Standup',
      );
      await container
          .read(planBlockRepositoryProvider)
          .createPlanBlock(planBlock);

      final controller = container.read(activeTimerControllerProvider.notifier);
      final res = await controller.startRoutine('Team Standup',
          planBlockId: 'block_custom');
      expect(res.success, isTrue);

      final state = container.read(activeTimerControllerProvider);
      expect(state.phaseName, 'Team Standup');
      expect(state.displayRemainingMs, 1800000);

      // Advance clock 35 mins (overrun: 2100000 ms) and finish phase
      fakeClock.advance(const Duration(minutes: 35));
      await controller.finishPhase();

      await container
          .read(sessionVerificationControllerProvider.notifier)
          .confirmSave();

      final updatedBlock = await container
          .read(planBlockRepositoryProvider)
          .getBlockById('block_custom');
      expect(updatedBlock?.status, PlanBlockStatus.completed);
      // The phase really ran 35 minutes, so that is the session's time: the
      // configured 30 minutes are not what the user spent.
      expect(updatedBlock?.actualDurationMs, 2100000);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      container.dispose();
      await db.close();
    });

    test(
        'open-ended routine tracks overrun when actual duration exceeds planned duration',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      const routine = Routine(
        id: 'r_open_ended',
        name: 'Open Flow',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Flow',
            durationMs: null,
            transition: TransitionPolicy.manual,
          ),
        ],
      );
      await container.read(routineRepositoryProvider).saveRoutine(routine);

      final planBlock = PlanBlock(
        id: 'block_overrun',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 900000, // 15 min planned
        routineId: 'r_open_ended',
      );
      await container
          .read(planBlockRepositoryProvider)
          .createPlanBlock(planBlock);

      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_open_ended',
          planBlockId: 'block_overrun');

      // Advance clock 25 mins (1500000 ms - overrun of +10 min)
      fakeClock.advance(const Duration(minutes: 25));
      await controller.finishPhase();

      await container
          .read(sessionVerificationControllerProvider.notifier)
          .confirmSave();

      final updatedBlock = await container
          .read(planBlockRepositoryProvider)
          .getBlockById('block_overrun');
      expect(updatedBlock?.status, PlanBlockStatus.completed);
      expect(updatedBlock?.actualDurationMs, 1500000);
      expect(updatedBlock!.actualDurationMs! > updatedBlock.plannedDurationMs,
          isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      container.dispose();
      await db.close();
    });

    test('rolls back plan block status to scheduled if engine start fails',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      const routine1 = Routine(
        id: 'r_first',
        name: 'First Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Phase 1',
            durationMs: 60000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );
      await container.read(routineRepositoryProvider).saveRoutine(routine1);

      final planBlock = PlanBlock(
        id: 'block_rollback',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 600000,
        routineId: 'r_first',
      );
      await container
          .read(planBlockRepositoryProvider)
          .createPlanBlock(planBlock);

      final controller = container.read(activeTimerControllerProvider.notifier);

      // Start first routine so engine is already running
      await controller.startRoutine('r_first');

      // Attempt to start second routine with planBlockId while engine is already running
      final result = await controller.startRoutine(
        'r_first',
        planBlockId: 'block_rollback',
      );
      expect(result.success, isFalse);

      final rolledBackBlock = await container
          .read(planBlockRepositoryProvider)
          .getBlockById('block_rollback');
      expect(rolledBackBlock?.status, PlanBlockStatus.scheduled);

      container.dispose();
      await db.close();
    });

    test(
        'transitions to completed triggers SessionVerificationController.prepareVerification',
        () async {
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
      addTearDown(container.dispose);
      addTearDown(db.close);

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);

      // Start routine and advance to completion
      await container
          .read(activeTimerControllerProvider.notifier)
          .startRoutine('r1');
      // The run has to have run for a while: a run without measurable time
      // produces no session at all.
      fakeClock.advance(const Duration(minutes: 5));
      final engine = container.read(timerEngineProvider);
      await engine.finishRun(engine.activeRunId!);

      final verificationState =
          container.read(sessionVerificationControllerProvider);
      expect(verificationState.isVisible, isTrue);
      expect(verificationState.candidateSession?.outcome,
          equals(SessionOutcome.completed));
    });

    test(
        'stopping or finishing does not re-delegate verification for an already handled runId',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      const testRoutine = Routine(
        id: 'r_multi_stop',
        name: 'Multi Stop Routine',
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
      addTearDown(container.dispose);
      addTearDown(db.close);

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.startRoutine('r_multi_stop');

      fakeClock.advance(const Duration(seconds: 15));
      await controller.stop();

      expect(container.read(sessionVerificationControllerProvider).isVisible,
          isTrue);

      // Save the draft session
      final saved = await container
          .read(sessionVerificationControllerProvider.notifier)
          .confirmSave();
      expect(saved, isTrue);
      expect(container.read(sessionVerificationControllerProvider).isVisible,
          isFalse);

      // Calling stop again for the same run does not re-delegate or re-open verification
      await controller.stop();
      expect(container.read(sessionVerificationControllerProvider).isVisible,
          isFalse);
    });

    test('a custom activity routine seeds its kind from the activity name',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      final controller = container.read(activeTimerControllerProvider.notifier);

      // A custom activity is a routine the app synthesises, so its kind is
      // seeded from the name - the same rule the editor follows for a new
      // phase.
      final res = await controller.startRoutine('Coffee Break');
      expect(res.success, isTrue);

      final repo = container.read(routineRepositoryProvider);
      final custom = (await repo.getAllRoutines())
          .firstWhere((r) => r.name == 'Coffee Break');
      expect(custom.phases.single.kind, PhaseKind.rest);
    });

    test(
        'a custom activity whose name says nothing about resting is a focus phase',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      final controller = container.read(activeTimerControllerProvider.notifier);

      final res = await controller.startRoutine('Email cleanup');
      expect(res.success, isTrue);

      final repo = container.read(routineRepositoryProvider);
      final custom = (await repo.getAllRoutines())
          .firstWhere((r) => r.name == 'Email cleanup');
      expect(custom.phases.single.kind, PhaseKind.focus);
    });

    test(
        'the stop fallback seeds the kind of a forgotten run from the phase name',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      const routine = Routine(
        id: 'r_forgotten_break',
        name: 'Forgotten Break',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Coffee Break',
            durationMs: 1500000,
            transition: TransitionPolicy.manual,
          ),
        ],
      );

      // The engine holds the run until it is stopped and forgets it then: the
      // timer controller has to build the run state by hand, and the routine
      // snapshot by hand as well.
      final engine = _ForgetfulEngine(
        TimerRunState(
          runId: 'run-forgotten-break',
          status: RunStatus.running,
          phaseStatus: PhaseStatus.active,
          currentPhase: routine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 600000,
          stateVersion: 1,
          totalActiveElapsedMs: 600000,
          runStartedAtUtc: DateTime.utc(2026, 10, 16, 8, 50),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      final controller = container.read(activeTimerControllerProvider.notifier);
      await controller.stop();

      final verification =
          container.read(sessionVerificationControllerProvider);
      final session = verification.candidateSession!;

      // The phase the run ended on is a break, so the time it took is rest
      // time - both in the phase log and in the synthesised snapshot.
      expect(session.events.single.kind, PhaseKind.rest);
      expect(session.routineSnapshot.phases.single.kind, PhaseKind.rest);
    });

    test(
        'the stop fallback builds a saveable session when the engine forgets the run',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 9, 0));
      final fakeClient = FakeNotificationClient();

      const routine = Routine(
        id: 'r_forgotten',
        name: 'Forgotten Run',
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

      // The engine holds the run until it is stopped and forgets it then: the
      // timer controller has to build the run state by hand.
      final engine = _ForgetfulEngine(
        TimerRunState(
          runId: 'run-forgotten',
          status: RunStatus.running,
          phaseStatus: PhaseStatus.active,
          currentPhase: routine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 600000,
          stateVersion: 1,
          totalActiveElapsedMs: 600000,
          runStartedAtUtc: DateTime.utc(2026, 10, 16, 8, 50),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
          timerEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      final controller = container.read(activeTimerControllerProvider.notifier);
      expect(
        container.read(activeTimerControllerProvider).displayElapsedMs,
        600000,
      );

      await controller.stop();

      // The hand-built state carries the phase's time, so the session it
      // produces has a total that is the sum of its phases.
      final verification =
          container.read(sessionVerificationControllerProvider);
      expect(verification.isVisible, isTrue);
      final session = verification.candidateSession!;
      expect(session.totalDurationMs, 600000);
      expect(session.events.length, 1);
      expect(session.events[0].durationMs, 600000);
      expect(
        session.events.fold<int>(0, (sum, event) => sum + event.durationMs),
        session.totalDurationMs,
      );

      // And the session is saveable: it passes the validator and is written.
      final saved = await container
          .read(sessionVerificationControllerProvider.notifier)
          .confirmSave();
      expect(saved, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    test('wires SessionAppTracker lifecycle on start, pause, resume, and stop',
        () async {
      final db = createInMemoryTestDatabase();
      final fakeClock =
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();
      final mockTracker = MockSessionAppTracker();

      const sampleUsages = [
        AppUsageSummary(
          appName: 'VS Code',
          category: 'Development',
          sampleTitle: 'main.dart',
          durationMs: 50000,
        ),
      ];

      when(() => mockTracker.startSession(any(), now: any(named: 'now')))
          .thenReturn(null);
      when(() => mockTracker.pauseSession()).thenReturn(null);
      when(() => mockTracker.resumeSession()).thenReturn(null);
      when(() => mockTracker.stopSession(now: any(named: 'now')))
          .thenAnswer((_) async => sampleUsages);

      const testRoutine = Routine(
        id: 'r1',
        name: 'Pomodoro',
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
          sessionAppTrackerProvider.overrideWithValue(mockTracker),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);

      await container.read(routineRepositoryProvider).saveRoutine(testRoutine);
      final controller = container.read(activeTimerControllerProvider.notifier);

      // 1. Start routine
      await controller.startRoutine('r1');
      verify(() => mockTracker.startSession(any(), now: any(named: 'now')))
          .called(1);

      // 2. Pause routine
      await controller.pause();
      verify(() => mockTracker.pauseSession()).called(1);

      // 3. Resume routine
      await controller.resume();
      verify(() => mockTracker.resumeSession()).called(1);

      // Advance clock so active duration >= 1s min duration
      fakeClock.advance(const Duration(seconds: 10));

      // 4. Stop routine
      await controller.stop();
      verify(() => mockTracker.stopSession(now: any(named: 'now'))).called(1);

      // Verify that SessionVerificationController received the app usages
      final verificationState =
          container.read(sessionVerificationControllerProvider);
      expect(verificationState.isVisible, isTrue);
      expect(verificationState.appUsages, equals(sampleUsages));
    });
  });
}

/// An engine that forgets the run when it is stopped — the path where the
/// timer controller has to build the run state by hand.
class _ForgetfulEngine implements TimerEngine {
  _ForgetfulEngine(this._state);

  TimerRunState? _state;

  @override
  String? get activeRunId => _state?.runId;

  @override
  TimerRunState? getState(String runId) => _state;

  @override
  TimerRun? getActiveRun() => null;

  @override
  Future<TimerCommandResult> stop(String runId) async {
    _state = null;
    return const TimerCommandResult(success: true, stateVersion: 2);
  }

  @override
  Future<Duration> elapsed(String runId) async => Duration.zero;

  @override
  Stream<TimerRunState> get stateStream => const Stream.empty();

  @override
  Stream<TimerEvent> get eventStream => const Stream.empty();

  @override
  Future<void> recover() async {}

  @override
  void cancelBoundaryTimer() {}

  @override
  void dispose() {}

  @override
  Future<TimerCommandResult> start(String routineId) async =>
      const TimerCommandResult(success: false, stateVersion: 0);

  @override
  Future<TimerCommandResult> pause(String runId) async =>
      const TimerCommandResult(success: false, stateVersion: 0);

  @override
  Future<TimerCommandResult> resume(String runId) async =>
      const TimerCommandResult(success: false, stateVersion: 0);

  @override
  Future<TimerCommandResult> skipPhase(String runId) async =>
      const TimerCommandResult(success: false, stateVersion: 0);

  @override
  Future<TimerCommandResult> finishPhase(String runId) async =>
      const TimerCommandResult(success: false, stateVersion: 0);

  @override
  Future<TimerCommandResult> finishRun(String runId) async =>
      const TimerCommandResult(success: false, stateVersion: 0);
}
