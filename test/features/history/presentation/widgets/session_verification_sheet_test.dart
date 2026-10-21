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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Verify Focus Session'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Coding Sprint'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('+5m'));
      await tester.pumpAndSettle();

      expect(find.text('30:00'), findsOneWidget);
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
        ),
        routineSnapshot: testRoutine,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('-5m'));
      await tester.pumpAndSettle();

      expect(find.text('20:00'), findsOneWidget);
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
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
          activeElapsedMs: 60 * 1000,
          stateVersion: 1,
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
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
          activeElapsedMs: 25 * 60 * 1000,
          stateVersion: 1,
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
  });
}
