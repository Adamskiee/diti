import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti/src/features/history/presentation/controllers/session_verification_controller.dart';

class MockSessionRepository extends Mock implements SessionRepository {}
class MockPlanBlockRepository extends Mock implements PlanBlockRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SessionRecord(
        sessionId: 'dummy',
        routineId: 'r',
        routineName: 'R',
        startedAtUtc: DateTime.now().toUtc(),
        endedAtUtc: DateTime.now().toUtc(),
        totalDurationMs: 1000,
        outcome: SessionOutcome.completed,
        routineSnapshot: const Routine(
          id: 'r',
          name: 'R',
          phases: [],
          repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        ),
      ),
    );
    registerFallbackValue(
      PlanBlock(
        id: 'dummy',
        planDate: '2026-10-20',
        scheduledStartUtc: DateTime.utc(2026, 10, 20),
        timezoneId: 'UTC',
        plannedDurationMs: 1000,
      ),
    );
    registerFallbackValue(PlanBlockStatus.scheduled);
  });

  group('SessionVerificationController', () {
    late MockSessionRepository mockSessionRepo;
    late MockPlanBlockRepository mockPlanRepo;
    late SessionVerificationController controller;

    const testRoutine = Routine(
      id: 'routine-focus',
      name: 'Flow Focus',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [
        RoutinePhase(
          id: 'p1',
          name: 'Focus Sprint',
          durationMs: 1500000,
          transition: TransitionPolicy.manual,
        ),
      ],
    );

    setUp(() {
      mockSessionRepo = MockSessionRepository();
      mockPlanRepo = MockPlanBlockRepository();
      controller = SessionVerificationController(
        sessionRepository: mockSessionRepo,
        planBlockRepository: mockPlanRepo,
      );
    });

    test('cancelled run < 1s is discarded silently, plan block reverted', () async {
      when(() => mockPlanRepo.getBlockById('block-123')).thenAnswer(
        (_) async => PlanBlock(
          id: 'block-123',
          planDate: '2026-10-20',
          scheduledStartUtc: DateTime.utc(2026, 10, 20),
          timezoneId: 'UTC',
          routineId: 'routine-focus',
          plannedDurationMs: 1500000,
          status: PlanBlockStatus.inProgress,
        ),
      );
      when(() => mockPlanRepo.updatePlanBlock(any())).thenAnswer((_) async {});

      final runState = TimerRunState(
        runId: 'run-short',
        status: RunStatus.cancelled,
        phaseStatus: PhaseStatus.active,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 500, // 500ms < 1s (SessionValidator.minDurationMs)
        completedPhases: _focusLedger(500),
        runStartedAtUtc: _runStart,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        planBlockId: 'block-123',
      );

      expect(controller.state.isVisible, isFalse);
      verify(() => mockPlanRepo.updatePlanBlock(any(
        that: isA<PlanBlock>().having((b) => b.status, 'status', PlanBlockStatus.scheduled),
      ))).called(1);
      verifyNever(() => mockSessionRepo.recordSession(any()));
    });

    test('cancelled run with measurable time >= 1s opens verification sheet', () async {
      final runState = TimerRunState(
        runId: 'run-short-cancel',
        status: RunStatus.cancelled,
        phaseStatus: PhaseStatus.active,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 45000, // 45 seconds >= 1s
        completedPhases: _focusLedger(45000),
        runStartedAtUtc: _runStart,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      expect(controller.state.isVisible, isTrue);
      expect(controller.state.draftDurationMs, equals(45000));
      expect(controller.state.draftRoutineName, equals('Flow Focus'));
      expect(controller.state.candidateSession?.outcome, equals(SessionOutcome.cancelled));
    });

    test('completed run of any duration opens verification sheet', () async {
      final runState = TimerRunState(
        runId: 'run-completed',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 1500000,
        completedPhases: _focusLedger(1500000),
        runStartedAtUtc: _runStart,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      expect(controller.state.isVisible, isTrue);
      expect(controller.state.candidateSession?.outcome, equals(SessionOutcome.completed));
    });

    test('adjustDuration modifies draftDurationMs clamped at >= 1000ms', () async {
      final runState = TimerRunState(
        runId: 'run-adj',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      controller.adjustDuration(const Duration(minutes: 5));
      expect(controller.state.draftDurationMs, equals(360000));

      controller.adjustDuration(const Duration(minutes: -10));
      expect(controller.state.draftDurationMs, equals(1000)); // Min clamped
    });

    test('setDurationMs updates draftDurationMs clamped between min and max duration', () async {
      final runState = TimerRunState(
        runId: 'run-set-dur',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      controller.setDurationMs(500); // Below 1,000ms
      expect(controller.state.draftDurationMs, equals(SessionValidator.minDurationMs));

      controller.setDurationMs(500000);
      expect(controller.state.draftDurationMs, equals(500000));

      controller.setDurationMs(100000000); // Above 86,400,000ms
      expect(controller.state.draftDurationMs, equals(SessionValidator.maxDurationMs));
    });

    test('confirmSave with increased duration anchors endedAtUtc and keeps the run start',
        () async {
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) async {});

      final fixedNow = DateTime.now().toUtc();
      final runState = TimerRunState(
        runId: 'run-increase',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        nowUtc: fixedNow,
      );

      controller.adjustDuration(const Duration(minutes: 5)); // 60s + 300s = 360,000ms
      final saved = await controller.confirmSave();

      expect(saved, isTrue);
      expect(controller.state.isVisible, isFalse);
      verify(() => mockSessionRepo.recordSession(any(
        that: isA<SessionRecord>()
            .having((s) => s.endedAtUtc, 'endedAtUtc', fixedNow)
            .having((s) => s.totalDurationMs, 'totalDurationMs', 360000)
            .having((s) => s.startedAtUtc, 'startedAtUtc', _runStart),
      ))).called(1);
    });

    test('confirmSave with empty routine name fails validation and preserves sheet', () async {
      final runState = TimerRunState(
        runId: 'run-empty-name',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      controller.setRoutineName('   ');
      final result = await controller.confirmSave();

      expect(result, isFalse);
      expect(controller.state.isVisible, isTrue);
      expect(controller.state.validationError, isNotNull);
      expect(controller.state.validationError, isNotEmpty);
      verifyNever(() => mockSessionRepo.recordSession(any()));
    });

    test('confirmSave sets validationError and resets isSaving when repository throws', () async {
      when(() => mockSessionRepo.recordSession(any())).thenThrow(Exception('database write failed'));

      final runState = TimerRunState(
        runId: 'run-throw',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      final result = await controller.confirmSave();

      expect(result, isFalse);
      expect(controller.state.isVisible, isTrue);
      expect(controller.state.isSaving, isFalse);
      expect(controller.state.validationError, contains('Failed to save session: Exception: database write failed'));
    });

    test('confirmSave validates, persists to repository, links plan block, and closes sheet', () async {
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) async {});
      when(() => mockPlanRepo.linkSession(
        blockId: any(named: 'blockId'),
        sessionId: any(named: 'sessionId'),
        actualDurationMs: any(named: 'actualDurationMs'),
        status: any(named: 'status'),
      )).thenAnswer((_) async {});

      final runState = TimerRunState(
        runId: 'run-save',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 1500000,
        completedPhases: _focusLedger(1500000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        planBlockId: 'block-save',
      );

      controller.setRoutineName('Deep Research');
      final result = await controller.confirmSave();

      expect(result, isTrue);
      expect(controller.state.isVisible, isFalse);
      verify(() => mockSessionRepo.recordSession(any(
        that: isA<SessionRecord>()
            .having((s) => s.routineName, 'routineName', 'Deep Research')
            .having((s) => s.totalDurationMs, 'totalDurationMs', 1500000),
      ))).called(1);
      verify(() => mockPlanRepo.linkSession(
        blockId: 'block-save',
        sessionId: any(named: 'sessionId'),
        actualDurationMs: 1500000,
        status: PlanBlockStatus.completed,
      )).called(1);
    });

    test('discard reverts plan block and closes sheet without saving', () async {
      when(() => mockPlanRepo.getBlockById('block-disc')).thenAnswer(
        (_) async => PlanBlock(
          id: 'block-disc',
          planDate: '2026-10-20',
          scheduledStartUtc: DateTime.utc(2026, 10, 20),
          timezoneId: 'UTC',
          routineId: 'routine-focus',
          plannedDurationMs: 1500000,
          status: PlanBlockStatus.inProgress,
        ),
      );
      when(() => mockPlanRepo.updatePlanBlock(any())).thenAnswer((_) async {});

      final runState = TimerRunState(
        runId: 'run-disc',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 1500000,
        completedPhases: _focusLedger(1500000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        planBlockId: 'block-disc',
      );

      await controller.discard();

      expect(controller.state.isVisible, isFalse);
      verify(() => mockPlanRepo.updatePlanBlock(any(
        that: isA<PlanBlock>().having((b) => b.status, 'status', PlanBlockStatus.scheduled),
      ))).called(1);
      verifyNever(() => mockSessionRepo.recordSession(any()));
    });

    test('confirmSave returns false immediately when re-entrant while isSaving is true', () async {
      final completer = Completer<void>();
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) => completer.future);

      final runState = TimerRunState(
        runId: 'run-reentrant',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );
      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      final firstCallFuture = controller.confirmSave();
      expect(controller.state.isSaving, isTrue);

      final secondCallResult = await controller.confirmSave();
      expect(secondCallResult, isFalse);

      completer.complete();
      final firstCallResult = await firstCallFuture;
      expect(firstCallResult, isTrue);
      verify(() => mockSessionRepo.recordSession(any())).called(1);
    });

    test('a multi-phase session totals every phase', () async {
      final runState = TimerRunState(
        runId: 'run-multi',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        completedPhases: [
          _ledgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus',
            kind: PhaseKind.focus,
            durationMs: 1500000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
          ),
          _ledgerEntry(
            phaseId: 'p2',
            phaseName: 'Break',
            kind: PhaseKind.rest,
            durationMs: 300000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 30),
          ),
        ],
        totalActiveElapsedMs: 1800000,
        runStartedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        nowUtc: DateTime.utc(2026, 10, 20, 10, 30),
      );

      final session = controller.state.candidateSession!;
      expect(session.totalDurationMs, 1800000);
      expect(session.events.length, 2);
      expect(session.events[0].phaseName, 'Focus');
      expect(session.events[0].kind, PhaseKind.focus);
      expect(session.events[1].kind, PhaseKind.rest);
      expect(session.events[0].durationMs, 1500000);
      expect(session.events[1].durationMs, 300000);
      expect(controller.state.phaseBreakdown.length, 2);
    });

    test('the breakdown sums to the total straight after preparation',
        () async {
      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      final breakdown = controller.state.phaseBreakdown;
      expect(
        breakdown.fold<int>(0, (sum, entry) => sum + entry.durationMs),
        controller.state.draftDurationMs,
      );
      expect(
        controller.state.draftDurationMs,
        controller.state.candidateSession!.totalDurationMs,
      );
    });

    test('a run whose breakdown is empty is discarded', () async {
      final runState = TimerRunState(
        runId: 'run-without-ledger',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 600000,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      expect(controller.state.candidateSession, isNull);
      expect(controller.state.isVisible, isFalse);
    });

    test('the session start is the run real start, not end minus active time',
        () async {
      final runStart = DateTime.utc(2026, 10, 20, 8, 0);
      final runEnd = DateTime.utc(2026, 10, 20, 10, 0); // two hours later
      final runState = TimerRunState(
        runId: 'run-real-start',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        completedPhases: [
          _ledgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus Sprint',
            kind: PhaseKind.focus,
            durationMs: 1500000,
            startedAtUtc: runStart,
            endedAtUtc: DateTime.utc(2026, 10, 20, 8, 25),
          ),
        ],
        totalActiveElapsedMs: 1500000,
        runStartedAtUtc: runStart,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        nowUtc: runEnd,
      );

      expect(controller.state.candidateSession!.startedAtUtc, runStart);
    });

    test('every event falls inside the validator window', () async {
      final runStart = DateTime.utc(2026, 10, 20, 10, 0);
      final runEnd = DateTime.utc(2026, 10, 20, 11, 0); // 30 minutes of pause
      final runState = TimerRunState(
        runId: 'run-paused',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        completedPhases: [
          _ledgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus Sprint',
            kind: PhaseKind.focus,
            durationMs: 1500000,
            startedAtUtc: runStart,
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
          ),
          _ledgerEntry(
            phaseId: 'p2',
            phaseName: 'Break',
            kind: PhaseKind.rest,
            durationMs: 300000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 55),
            endedAtUtc: runEnd,
          ),
        ],
        totalActiveElapsedMs: 1800000,
        runStartedAtUtc: runStart,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        nowUtc: runEnd,
      );

      final session = controller.state.candidateSession!;
      expect(SessionValidator.validate(session).isValid, isTrue);
      expect(session.totalDurationMs, 1800000);
    });

    test('a cancelled run with no active time produces no session', () async {
      final runState = TimerRunState(
        runId: 'run-no-time',
        status: RunStatus.cancelled,
        phaseStatus: PhaseStatus.active,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 0,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      expect(controller.state.candidateSession, isNull);
      expect(controller.state.isVisible, isFalse);
    });

    test('a cancelled Pomodoro during its break is not discarded', () async {
      final runState = TimerRunState(
        runId: 'run-pomodoro-cancel',
        status: RunStatus.cancelled,
        phaseStatus: PhaseStatus.active,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        completedPhases: [
          _ledgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus',
            kind: PhaseKind.focus,
            durationMs: 1500000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
          ),
        ],
        totalActiveElapsedMs: 1500000,
        runStartedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      expect(controller.state.candidateSession, isNotNull);
      expect(controller.state.candidateSession!.totalDurationMs, 1500000);
    });

    test('adjusting the duration applies the delta to the last focus phase',
        () async {
      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      controller.adjustDuration(const Duration(minutes: 5));

      final breakdown = controller.state.phaseBreakdown;
      expect(controller.state.draftDurationMs, 2100000);
      expect(breakdown[0].durationMs, 1800000);
      expect(breakdown[1].durationMs, 300000);
      expect(
        breakdown.fold<int>(0, (sum, entry) => sum + entry.durationMs),
        controller.state.draftDurationMs,
      );
    });

    test('adjusting below the phase length clamps instead of going negative',
        () async {
      final runState = TimerRunState(
        runId: 'run-short-focus',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        completedPhases: [
          _ledgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus Sprint',
            kind: PhaseKind.focus,
            durationMs: 180000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 3),
          ),
        ],
        totalActiveElapsedMs: 180000,
        runStartedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      controller.adjustDuration(const Duration(minutes: -5));

      expect(controller.state.draftDurationMs, SessionValidator.minDurationMs);
      expect(
        controller.state.phaseBreakdown.every((entry) => entry.durationMs >= 0),
        isTrue,
      );
    });

    test('adjusting by more than the phase holds moves the total by what fits',
        () async {
      final runState = TimerRunState(
        runId: 'run-short-phases',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        completedPhases: [
          _ledgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus Sprint',
            kind: PhaseKind.focus,
            durationMs: 180000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 3),
          ),
          _ledgerEntry(
            phaseId: 'p2',
            phaseName: 'Break',
            kind: PhaseKind.rest,
            durationMs: 120000,
            startedAtUtc: DateTime.utc(2026, 10, 20, 10, 3),
            endedAtUtc: DateTime.utc(2026, 10, 20, 10, 5),
          ),
        ],
        totalActiveElapsedMs: 300000,
        runStartedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      controller.adjustDuration(const Duration(minutes: -4));

      // The focus phase holds 3 minutes, so it can only give up 3 of the 4
      // minutes: the total moves by what the phase absorbed.
      final breakdown = controller.state.phaseBreakdown;
      expect(breakdown[0].durationMs, 0);
      expect(breakdown[1].durationMs, 120000);
      expect(controller.state.draftDurationMs, 120000);
      expect(
        breakdown.fold<int>(0, (sum, entry) => sum + entry.durationMs),
        controller.state.draftDurationMs,
      );
    });

    test('setDurationMs keeps the total equal to the sum of the phases',
        () async {
      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      controller.setDurationMs(60000);

      // The focus phase holds 25 minutes, so the total can only fall to the
      // break's 5 minutes: the total moves by what the phase absorbed.
      final breakdown = controller.state.phaseBreakdown;
      expect(breakdown[0].durationMs, 0);
      expect(breakdown[1].durationMs, 300000);
      expect(controller.state.draftDurationMs, 300000);
      expect(
        breakdown.fold<int>(0, (sum, entry) => sum + entry.durationMs),
        controller.state.draftDurationMs,
      );
    });

    test('confirmSave stores the adjusted breakdown in the session events',
        () async {
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) async {});

      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      controller.adjustDuration(const Duration(minutes: 5));
      final saved = await controller.confirmSave();

      expect(saved, isTrue);
      verify(() => mockSessionRepo.recordSession(any(
        that: isA<SessionRecord>()
            .having((s) => s.totalDurationMs, 'totalDurationMs', 2100000)
            .having((s) => s.events.length, 'events.length', 2)
            .having((s) => s.events[0].durationMs, 'focus event duration', 1800000)
            .having((s) => s.events[1].durationMs, 'rest event duration', 300000)
            .having((s) => s.events[0].kind, 'focus event kind', PhaseKind.focus)
            .having((s) => s.events[1].kind, 'rest event kind', PhaseKind.rest),
      ))).called(1);
    });
    test('confirmSave prevents re-verifying the same runId again', () async {
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) async {});

      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      final saved = await controller.confirmSave();
      expect(saved, isTrue);
      expect(controller.state.isVisible, isFalse);

      // Attempt to re-verify the same runId
      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      // Should remain invisible / not re-opened
      expect(controller.state.isVisible, isFalse);
      expect(controller.state.candidateSession, isNull);
    });

    test('discard prevents re-verifying the same runId again', () async {
      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      await controller.discard();
      expect(controller.state.isVisible, isFalse);

      // Attempt to re-verify the same runId
      await controller.prepareVerification(
        runState: _multiPhaseRunState(),
        routineSnapshot: testRoutine,
      );

      // Should remain invisible / not re-opened
      expect(controller.state.isVisible, isFalse);
      expect(controller.state.candidateSession, isNull);
    });

    test('prepareVerification populates state.appUsages', () async {
      final runState = TimerRunState(
        runId: 'run-app-usages',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );

      final appUsages = [
        const AppUsageSummary(
          appName: 'VS Code',
          category: 'Development',
          sampleTitle: 'editor.dart',
          durationMs: 40000,
        ),
        const AppUsageSummary(
          appName: 'Terminal',
          category: 'Development',
          sampleTitle: 'bash',
          durationMs: 20000,
        ),
      ];

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        appUsages: appUsages,
      );

      expect(controller.state.appUsages, equals(appUsages));
    });

    test('confirmSave maps state.appUsages to SessionAppUsageRecord and persists to SessionRepository', () async {
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) async {});

      final runState = TimerRunState(
        runId: 'run-save-usages',
        status: RunStatus.completed,
        phaseStatus: PhaseStatus.finished,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 0,
        stateVersion: 1,
        totalActiveElapsedMs: 60000,
        completedPhases: _focusLedger(60000),
        runStartedAtUtc: _runStart,
      );

      final appUsages = [
        const AppUsageSummary(
          appName: 'VS Code',
          category: 'Development',
          sampleTitle: 'editor.dart',
          durationMs: 40000,
        ),
      ];

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
        appUsages: appUsages,
      );

      final saved = await controller.confirmSave();

      expect(saved, isTrue);
      final captured = verify(() => mockSessionRepo.recordSession(captureAny())).captured;
      final savedRecord = captured.single as SessionRecord;
      expect(savedRecord.appUsages.length, equals(1));
      expect(savedRecord.appUsages[0].appName, equals('VS Code'));
      expect(savedRecord.appUsages[0].category, equals('Development'));
      expect(savedRecord.appUsages[0].sampleTitle, equals('editor.dart'));
      expect(savedRecord.appUsages[0].durationMs, equals(40000));
      expect(savedRecord.appUsages[0].sessionId, equals(savedRecord.sessionId));
      expect(savedRecord.appUsages[0].id, isNotEmpty);
    });
  });
}

/// A ledger entry for a phase that ended, with the active time it took.
PhaseLedgerEntry _ledgerEntry({
  required String phaseId,
  required String phaseName,
  required PhaseKind kind,
  required int durationMs,
  required DateTime startedAtUtc,
  required DateTime endedAtUtc,
  PhaseStatus outcome = PhaseStatus.finished,
}) {
  return PhaseLedgerEntry(
    phaseId: phaseId,
    phaseName: phaseName,
    kind: kind,
    phaseIndex: 0,
    repeatIndex: 0,
    durationMs: durationMs,
    outcome: outcome,
    startedAtUtc: startedAtUtc,
    endedAtUtc: endedAtUtc,
  );
}

/// When the run behind the hand-built states started.
final DateTime _runStart = DateTime.utc(2026, 10, 20, 10, 0);

/// A ledger with a single focus phase that took [durationMs] — the ledger of
/// an ended run, whose time lives in the ledger and not in the accumulator.
List<PhaseLedgerEntry> _focusLedger(int durationMs) {
  return [
    _ledgerEntry(
      phaseId: 'p1',
      phaseName: 'Focus Sprint',
      kind: PhaseKind.focus,
      durationMs: durationMs,
      startedAtUtc: _runStart,
      endedAtUtc: _runStart.add(Duration(milliseconds: durationMs)),
    ),
  ];
}

/// A finished run of a focus phase and a break phase.
TimerRunState _multiPhaseRunState() {
  return TimerRunState(
    runId: 'run-multi-adjust',
    status: RunStatus.completed,
    phaseStatus: PhaseStatus.finished,
    currentPhase: const RoutinePhase(
      id: 'p2',
      name: 'Break',
      transition: TransitionPolicy.manual,
    ),
    currentPhaseIndex: 1,
    repeatIndex: 0,
    activeElapsedMs: 0,
    stateVersion: 1,
    completedPhases: [
      _ledgerEntry(
        phaseId: 'p1',
        phaseName: 'Focus',
        kind: PhaseKind.focus,
        durationMs: 1500000,
        startedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
        endedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
      ),
      _ledgerEntry(
        phaseId: 'p2',
        phaseName: 'Break',
        kind: PhaseKind.rest,
        durationMs: 300000,
        startedAtUtc: DateTime.utc(2026, 10, 20, 10, 25),
        endedAtUtc: DateTime.utc(2026, 10, 20, 10, 30),
      ),
    ],
    totalActiveElapsedMs: 1800000,
    runStartedAtUtc: DateTime.utc(2026, 10, 20, 10, 0),
  );
}
