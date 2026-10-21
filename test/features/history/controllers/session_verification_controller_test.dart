import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti/src/features/history/domain/draft_session.dart';
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

    test('noise filter: cancelled run < 60s is discarded silently, plan block reverted', () async {
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
        activeElapsedMs: 45000, // 45 seconds < 60s
        stateVersion: 1,
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

    test('cancelled run >= 60s opens verification sheet', () async {
      final runState = TimerRunState(
        runId: 'run-long-cancel',
        status: RunStatus.cancelled,
        phaseStatus: PhaseStatus.active,
        currentPhase: testRoutine.phases.first,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        activeElapsedMs: 120000, // 2 minutes
        stateVersion: 1,
      );

      await controller.prepareVerification(
        runState: runState,
        routineSnapshot: testRoutine,
      );

      expect(controller.state.isVisible, isTrue);
      expect(controller.state.draftDurationMs, equals(120000));
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
        activeElapsedMs: 1500000,
        stateVersion: 1,
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
        activeElapsedMs: 60000,
        stateVersion: 1,
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
        activeElapsedMs: 1500000,
        stateVersion: 1,
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
        activeElapsedMs: 1500000,
        stateVersion: 1,
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
  });
}
