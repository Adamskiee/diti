import 'dart:async';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti/src/features/history/presentation/controllers/session_verification_controller.dart';
import 'package:diti/src/features/history/presentation/widgets/session_verification_sheet.dart';
import 'package:diti/src/features/history/providers/history_providers.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockPlanBlockRepository extends Mock implements PlanBlockRepository {}

void main() {
  group('SessionVerificationSheet Widget Tests', () {
    late MockSessionRepository mockSessionRepo;
    late MockPlanBlockRepository mockPlanRepo;
    late SessionVerificationController controller;

    const testRoutine = Routine(
      id: 'r1',
      name: 'Coding Sprint',
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

    /// A routine with one focus phase and one rest phase.
    const twoPhaseRoutine = Routine(
      id: 'r2',
      name: 'Deep Work Session',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [
        RoutinePhase(
          id: 'p1',
          name: 'Deep Work',
          durationMs: 1200000,
          transition: TransitionPolicy.manual,
          kind: PhaseKind.focus,
        ),
        RoutinePhase(
          id: 'p2',
          name: 'Short Break',
          durationMs: 300000,
          transition: TransitionPolicy.manual,
          kind: PhaseKind.rest,
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

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          sessionVerificationControllerProvider
              .overrideWith((ref) => controller),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SessionVerificationSheet(),
          ),
        ),
      );
    }

    /// The number on the duration card — the session's total time.
    String totalDurationText(WidgetTester tester) {
      final text =
          tester.widget<Text>(find.byKey(const Key('total_duration_value')));
      return text.data ?? '';
    }

    /// Drives the sheet with a draft of a focus phase and a rest phase:
    /// 20 minutes of focus and 5 minutes of rest, 25 minutes in total.
    Future<void> prepareTwoPhaseDraft() async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-two-phase',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: twoPhaseRoutine.phases.last,
          currentPhaseIndex: 1,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _twoPhaseLedger(),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: twoPhaseRoutine,
      );
    }

    testWidgets(
        'renders headline, outcome chip, routine text field, and duration',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w1',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Verify Session'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Coding Sprint'), findsOneWidget);
      expect(totalDurationText(tester), '25:00');
      expect(find.text('Save to Analytics'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('tapping increment chip (+5m) updates duration display',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w2',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();

      expect(totalDurationText(tester), '30:00');
    });

    testWidgets('tapping decrement chip (-5m) updates duration display',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w2b',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('-5m'));
      await tester.pumpAndSettle();

      expect(totalDurationText(tester), '20:00');
    });

    testWidgets(
        'clearing routine name and tapping Save displays validation error',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w3',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Save to Analytics'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Routine name cannot be empty'), findsOneWidget);
    });

    testWidgets(
        'tapping Save to Analytics with valid state saves and calls repo',
        (tester) async {
      registerFallbackValue(SessionRecord(
        sessionId: 'dummy',
        routineId: 'dummy',
        routineName: 'dummy',
        startedAtUtc: DateTime.now().toUtc(),
        endedAtUtc: DateTime.now().toUtc(),
        totalDurationMs: 1000,
        outcome: SessionOutcome.completed,
        routineSnapshot: testRoutine,
      ));
      when(() => mockSessionRepo.recordSession(any())).thenAnswer((_) async {});

      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w4',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Analytics'));
      await tester.pumpAndSettle();

      verify(() => mockSessionRepo.recordSession(any())).called(1);
    });

    testWidgets(
        'tapping Discard when duration > 5m shows alert dialog and cancels properly',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w5',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Session?'), findsOneWidget);
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Session?'), findsNothing);
      expect(controller.state.candidateSession, isNotNull);
    });

    testWidgets(
        'tapping Discard when duration <= 5m discards immediately without dialog',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w6',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 60 * 1000,
          completedPhases: _focusLedger(60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Session?'), findsNothing);
      expect(controller.state.candidateSession, isNull);
    });

    testWidgets(
        'confirming Discard in dialog for session > 5m calls controller.discard()',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w7',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Session?'), findsOneWidget);

      final dialogDiscardButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Discard'),
      );
      await tester.tap(dialogDiscardButton);
      await tester.pumpAndSettle();

      expect(find.text('Discard Session?'), findsNothing);
      expect(controller.state.candidateSession, isNull);
    });

    testWidgets('inputs and chips are disabled while isSaving is true',
        (tester) async {
      final saveCompleter = Completer<void>();
      registerFallbackValue(SessionRecord(
        sessionId: 'dummy',
        routineId: 'dummy',
        routineName: 'dummy',
        startedAtUtc: DateTime.now().toUtc(),
        endedAtUtc: DateTime.now().toUtc(),
        totalDurationMs: 1000,
        outcome: SessionOutcome.completed,
        routineSnapshot: testRoutine,
      ));
      when(() => mockSessionRepo.recordSession(any()))
          .thenAnswer((_) => saveCompleter.future);

      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w8',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Save to trigger isSaving: true
      await tester.tap(find.text('Save to Analytics'));
      await tester.pump();

      expect(controller.state.isSaving, isTrue);

      final textField =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isFalse);

      final chips = tester.widgetList<ActionChip>(find.byType(ActionChip));
      for (final chip in chips) {
        expect(chip.onPressed, isNull);
      }

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget(popScopeFinder) as PopScope;
      expect(popScope.canPop, isFalse);

      saveCompleter.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('Android back pop invokes discard on controller',
        (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-w9',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: testRoutine.phases.first,
          currentPhaseIndex: 0,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _focusLedger(25 * 60 * 1000),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final dynamic popScopeWidget = tester.widget(popScopeFinder);
      popScopeWidget.onPopInvokedWithResult(true, null);
      await tester.pumpAndSettle();

      expect(controller.state.candidateSession, isNull);
    });

    testWidgets('shows one row per phase with its kind and duration',
        (tester) async {
      await prepareTwoPhaseDraft();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Deep Work'), findsOneWidget);
      expect(find.text('Short Break'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Focus'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Rest'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('marks a skipped phase as skipped', (tester) async {
      await controller.prepareVerification(
        runState: TimerRunState(
          runId: 'run-skipped',
          status: RunStatus.completed,
          phaseStatus: PhaseStatus.finished,
          currentPhase: twoPhaseRoutine.phases.last,
          currentPhaseIndex: 1,
          repeatIndex: 0,
          activeElapsedMs: 0,
          stateVersion: 1,
          totalActiveElapsedMs: 25 * 60 * 1000,
          completedPhases: _twoPhaseLedgerWithSkippedBreak(),
          runStartedAtUtc: _runStart,
        ),
        routineSnapshot: twoPhaseRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The abandoned break carries the marker, the phase that ran to its
      // end does not. Both keep the time they actually took.
      final skippedRow = find.ancestor(
        of: find.text('Short Break'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: skippedRow, matching: find.text('Skipped')),
        findsOneWidget,
      );
      final finishedRow = find.ancestor(
        of: find.text('Deep Work'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: finishedRow, matching: find.text('Skipped')),
        findsNothing,
      );
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('the header reads Verify Session, not Verify Focus Session',
        (tester) async {
      await prepareTwoPhaseDraft();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Verify Session'), findsOneWidget);
      expect(find.text('Verify Focus Session'), findsNothing);
    });

    testWidgets('the duration card reads Total Time', (tester) async {
      await prepareTwoPhaseDraft();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Total Focus Time'), findsNothing);
    });

    testWidgets('adjusting the duration updates the phase row',
        (tester) async {
      await prepareTwoPhaseDraft();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('20:00'), findsOneWidget);

      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();

      // The focus phase absorbs the adjustment; the rest phase does not.
      expect(find.text('20:00'), findsNothing);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);
      expect(totalDurationText(tester), '30:00');
    });

    testWidgets('renders no phase list when the draft has no phases',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('phase_breakdown')), findsNothing);
    });
  });
}

/// When the run behind the hand-built states started.
final DateTime _runStart = DateTime.utc(2026, 10, 20, 10, 0);

/// A ledger with a single focus phase that took [durationMs] — the ledger of
/// an ended run, whose time lives in the ledger and not in the accumulator.
List<PhaseLedgerEntry> _focusLedger(int durationMs) {
  return [
    PhaseLedgerEntry(
      phaseId: 'p1',
      phaseName: 'Focus',
      kind: PhaseKind.focus,
      phaseIndex: 0,
      repeatIndex: 0,
      durationMs: durationMs,
      outcome: PhaseStatus.finished,
      startedAtUtc: _runStart,
      endedAtUtc: _runStart.add(Duration(milliseconds: durationMs)),
    ),
  ];
}

/// A ledger with a focus phase of 20 minutes and a rest phase of 5 minutes —
/// 25 minutes in total, the way a run with a break records itself.
List<PhaseLedgerEntry> _twoPhaseLedger() {
  return [
    PhaseLedgerEntry(
      phaseId: 'p1',
      phaseName: 'Deep Work',
      kind: PhaseKind.focus,
      phaseIndex: 0,
      repeatIndex: 0,
      durationMs: 20 * 60 * 1000,
      outcome: PhaseStatus.finished,
      startedAtUtc: _runStart,
      endedAtUtc: _runStart.add(const Duration(minutes: 20)),
    ),
    PhaseLedgerEntry(
      phaseId: 'p2',
      phaseName: 'Short Break',
      kind: PhaseKind.rest,
      phaseIndex: 1,
      repeatIndex: 0,
      durationMs: 5 * 60 * 1000,
      outcome: PhaseStatus.finished,
      startedAtUtc: _runStart.add(const Duration(minutes: 20)),
      endedAtUtc: _runStart.add(const Duration(minutes: 25)),
    ),
  ];
}

/// The same ledger, but the break was abandoned: it ran for five minutes and
/// was then skipped. The time it took still counts.
List<PhaseLedgerEntry> _twoPhaseLedgerWithSkippedBreak() {
  return [
    _twoPhaseLedger().first,
    PhaseLedgerEntry(
      phaseId: 'p2',
      phaseName: 'Short Break',
      kind: PhaseKind.rest,
      phaseIndex: 1,
      repeatIndex: 0,
      durationMs: 5 * 60 * 1000,
      outcome: PhaseStatus.skipped,
      startedAtUtc: _runStart.add(const Duration(minutes: 20)),
      endedAtUtc: _runStart.add(const Duration(minutes: 25)),
    ),
  ];
}
