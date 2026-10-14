import 'package:flutter_test/flutter_test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:focus_flow_notifications/src/domain/scheduled_boundary.dart';
import 'package:focus_flow_notifications/src/domain/boundary_window_calculator.dart';

void main() {
  group('BoundaryWindowCalculator', () {
    const calculator = BoundaryWindowCalculator();

    Routine createTestRoutine({
      required List<RoutinePhase> phases,
      RepeatRule repeatRule = const RepeatRule(mode: RepeatMode.count, count: 1),
    }) {
      return Routine(
        id: 'routine-1',
        name: 'Work Routine',
        repeatRule: repeatRule,
        phases: phases,
      );
    }

    TimerRun createTestRun({
      required Routine routine,
      RunStatus status = RunStatus.running,
      PhaseStatus phaseStatus = PhaseStatus.active,
      int currentPhaseIndex = 0,
      int repeatIndex = 0,
      int accumulatedMs = 0,
    }) {
      final now = DateTime.utc(2026, 10, 14, 10, 0, 0);
      return TimerRun(
        runId: 'run-100',
        routineSnapshot: routine,
        status: status,
        phaseStatus: phaseStatus,
        currentPhaseIndex: currentPhaseIndex,
        repeatIndex: repeatIndex,
        accumulatedMs: accumulatedMs,
        phaseStartedAtUtc: now,
        phaseStartedMonotonicMs: 0,
        pausedAtUtc: null,
        stateVersion: 1,
        lastEventId: 'evt-1',
      );
    }

    test('returns empty list if run is not running', () {
      final routine = createTestRoutine(phases: const [
        RoutinePhase(id: 'p1', name: 'Focus', durationMs: 1500000, transition: TransitionPolicy.auto),
      ]);
      final run = createTestRun(routine: routine, status: RunStatus.paused);

      final boundaries = calculator.calculateUpcomingBoundaries(
        run: run,
        currentUtc: DateTime.utc(2026, 10, 14, 10, 0, 0),
      );

      expect(boundaries, isEmpty);
    });

    test('returns empty list if phaseStatus is awaitingAction', () {
      final routine = createTestRoutine(phases: const [
        RoutinePhase(id: 'p1', name: 'Focus', durationMs: 1500000, transition: TransitionPolicy.manual),
      ]);
      final run = createTestRun(routine: routine, phaseStatus: PhaseStatus.awaitingAction);

      final boundaries = calculator.calculateUpcomingBoundaries(
        run: run,
        currentUtc: DateTime.utc(2026, 10, 14, 10, 0, 0),
      );

      expect(boundaries, isEmpty);
    });

    test('calculates single boundary for single auto phase', () {
      final routine = createTestRoutine(phases: const [
        RoutinePhase(id: 'p1', name: 'Focus', durationMs: 1500000, transition: TransitionPolicy.auto),
      ]);
      final run = createTestRun(routine: routine, accumulatedMs: 300000); // 5m elapsed, 20m remain
      final currentUtc = DateTime.utc(2026, 10, 14, 10, 5, 0);

      final boundaries = calculator.calculateUpcomingBoundaries(
        run: run,
        currentUtc: currentUtc,
      );

      expect(boundaries.length, equals(1));
      final ScheduledBoundary b = boundaries.first;
      expect(b.runId, equals('run-100'));
      expect(b.phaseId, equals('p1'));
      expect(b.phaseName, equals('Focus'));
      expect(b.scheduledUtc, equals(DateTime.utc(2026, 10, 14, 10, 25, 0)));
      expect(b.isTerminal, isTrue);
      expect(b.notificationId, isPositive);
    });

    test('looks ahead through consecutive auto phases up to manual transition', () {
      final routine = createTestRoutine(phases: const [
        RoutinePhase(id: 'p1', name: 'Focus', durationMs: 1200000, transition: TransitionPolicy.auto), // 20m
        RoutinePhase(id: 'p2', name: 'Break', durationMs: 300000, transition: TransitionPolicy.auto), // 5m
        RoutinePhase(id: 'p3', name: 'Reading', durationMs: 600000, transition: TransitionPolicy.manual), // 10m manual
        RoutinePhase(id: 'p4', name: 'Review', durationMs: 600000, transition: TransitionPolicy.auto),
      ]);
      final run = createTestRun(routine: routine, accumulatedMs: 0);
      final currentUtc = DateTime.utc(2026, 10, 14, 10, 0, 0);

      final boundaries = calculator.calculateUpcomingBoundaries(
        run: run,
        currentUtc: currentUtc,
      );

      // p1 -> p2 -> p3 (stops at p3 because transition is manual)
      expect(boundaries.length, equals(3));
      expect(boundaries[0].phaseId, equals('p1'));
      expect(boundaries[0].scheduledUtc, equals(DateTime.utc(2026, 10, 14, 10, 20, 0)));
      expect(boundaries[0].requiresAction, isFalse);

      expect(boundaries[1].phaseId, equals('p2'));
      expect(boundaries[1].scheduledUtc, equals(DateTime.utc(2026, 10, 14, 10, 25, 0)));
      expect(boundaries[1].requiresAction, isFalse);

      expect(boundaries[2].phaseId, equals('p3'));
      expect(boundaries[2].scheduledUtc, equals(DateTime.utc(2026, 10, 14, 10, 35, 0)));
      expect(boundaries[2].requiresAction, isTrue); // manual phase
    });

    test('halts lookahead when encountering open-ended phase', () {
      final routine = createTestRoutine(phases: const [
        RoutinePhase(id: 'p1', name: 'Focus', durationMs: 600000, transition: TransitionPolicy.auto),
        RoutinePhase(id: 'p2', name: 'Open Flow', durationMs: null, transition: TransitionPolicy.manual),
      ]);
      final run = createTestRun(routine: routine);
      final currentUtc = DateTime.utc(2026, 10, 14, 10, 0, 0);

      final boundaries = calculator.calculateUpcomingBoundaries(
        run: run,
        currentUtc: currentUtc,
      );

      expect(boundaries.length, equals(1));
      expect(boundaries[0].phaseId, equals('p1'));
    });

    test('handles repeating routine roll-over up to maxLookahead limit', () {
      final routine = createTestRoutine(
        phases: const [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 600000, transition: TransitionPolicy.auto), // 10m
          RoutinePhase(id: 'p2', name: 'Break', durationMs: 300000, transition: TransitionPolicy.auto), // 5m
        ],
        repeatRule: const RepeatRule(mode: RepeatMode.forever),
      );
      final run = createTestRun(routine: routine);
      final currentUtc = DateTime.utc(2026, 10, 14, 10, 0, 0);

      final boundaries = calculator.calculateUpcomingBoundaries(
        run: run,
        currentUtc: currentUtc,
        maxLookahead: 3,
      );

      expect(boundaries.length, equals(3));
      expect(boundaries[0].phaseId, equals('p1')); // repeat 0
      expect(boundaries[1].phaseId, equals('p2')); // repeat 0
      expect(boundaries[2].phaseId, equals('p1')); // repeat 1
    });

    test('notificationId is deterministic and positive', () {
      final id1 = BoundaryWindowCalculator.generateNotificationId('run-1', 0, 0);
      final id2 = BoundaryWindowCalculator.generateNotificationId('run-1', 0, 0);
      final id3 = BoundaryWindowCalculator.generateNotificationId('run-1', 1, 1);

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(id1, isPositive);
    });
  });
}
