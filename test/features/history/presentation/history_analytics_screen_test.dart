import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/features/history/presentation/history_analytics_screen.dart';
import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockPlanBlockRepository extends Mock implements PlanBlockRepository {}

void main() {
  late MockSessionRepository mockSessionRepo;
  late MockPlanBlockRepository mockPlanBlockRepo;

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    mockPlanBlockRepo = MockPlanBlockRepository();

    when(() => mockSessionRepo.getSessionsInRange(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockPlanBlockRepo.getBlocksForDate(any()))
        .thenAnswer((_) async => []);
  });

  testWidgets('HistoryAnalyticsScreen renders SegmentedButton and toggles tabs',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
          planBlockRepositoryProvider.overrideWithValue(mockPlanBlockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryAnalyticsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Tap History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
  });

  testWidgets(
      'HistoryAnalyticsScreen renders Tracked Activity card in Analytics tab when sessions have appUsages',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now().toUtc();
    final testSession = SessionRecord(
      sessionId: 's-analytics-test',
      routineId: 'r1',
      routineName: 'Focus Routine',
      startedAtUtc: now.subtract(const Duration(minutes: 30)),
      endedAtUtc: now,
      totalDurationMs: 1800000,
      outcome: SessionOutcome.completed,
      routineSnapshot: const Routine(
        id: 'r1',
        name: 'Focus Routine',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            durationMs: 1800000,
            transition: TransitionPolicy.manual,
          ),
        ],
      ),
      appUsages: const [
        SessionAppUsageRecord(
          id: 'u1',
          sessionId: 's-analytics-test',
          appName: 'VS Code',
          category: 'Development',
          sampleTitle: 'main.dart',
          durationMs: 1200000,
        ),
        SessionAppUsageRecord(
          id: 'u2',
          sessionId: 's-analytics-test',
          appName: 'Brave',
          category: 'YouTube',
          sampleTitle: 'Music - YouTube',
          durationMs: 600000,
        ),
      ],
    );

    when(() => mockSessionRepo.getSessionsInRange(any(), any()))
        .thenAnswer((_) async => [testSession]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
          planBlockRepositoryProvider.overrideWithValue(mockPlanBlockRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryAnalyticsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Analytics tab is showing and contains Tracked Activity
    expect(find.text('Tracked Activity'), findsOneWidget);
    expect(find.text('VS Code'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
  });
}
