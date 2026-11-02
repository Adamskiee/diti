import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/features/history/presentation/widgets/history_feed_view.dart';
import 'package:diti/src/features/history/presentation/widgets/session_feed_tile.dart';
import 'package:diti_database/diti_database.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_engine/timer_engine.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026, 10, 14));
  });

  late MockSessionRepository mockSessionRepo;

  setUp(() {
    mockSessionRepo = MockSessionRepository();
  });

  const routine = Routine(
    id: 'r1',
    name: 'Deep Focus',
    repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
    phases: [
      RoutinePhase(
        id: 'p1',
        name: 'Sprint',
        durationMs: 25 * 60 * 1000,
        transition: TransitionPolicy.auto,
      ),
    ],
  );

  testWidgets('HistoryFeedView shows empty state when no sessions found',
      (tester) async {
    when(() => mockSessionRepo.getSessionsInRange(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryFeedView(),
          ),
        ),
      ),
    );

    // Initial load
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No session history found'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('HistoryFeedView displays sessions and allows filtering',
      (tester) async {
    final s1 = SessionRecord(
      sessionId: 's1',
      routineName: 'Deep Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 9, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 9, 25),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
    );
    final s2 = SessionRecord(
      sessionId: 's2',
      routineName: 'Quick Break',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 5),
      totalDurationMs: 5 * 60 * 1000,
      outcome: SessionOutcome.cancelled,
      routineSnapshot: routine,
    );

    when(() => mockSessionRepo.getSessionsInRange(any(), any()))
        .thenAnswer((_) async => [s1, s2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryFeedView(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SessionFeedTile), findsNWidgets(2));
    expect(find.text('Deep Focus'), findsOneWidget);
    expect(find.text('Quick Break'), findsOneWidget);

    // Filter by Completed
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.byType(SessionFeedTile), findsOneWidget);
    expect(find.text('Deep Focus'), findsOneWidget);
    expect(find.text('Quick Break'), findsNothing);

    // Filter by Cancelled
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();

    expect(find.byType(SessionFeedTile), findsOneWidget);
    expect(find.text('Quick Break'), findsOneWidget);
    expect(find.text('Deep Focus'), findsNothing);
  });
}
