import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/presentation/controllers/history_feed_controller.dart';
import 'package:diti/src/features/history/providers/history_providers.dart';
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

  test('HistoryFeedController filters sessions and handles deletion', () async {
    const routine = Routine(
      id: 'r1',
      name: 'Focus',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [],
    );
    final s1 = SessionRecord(
      sessionId: 's1',
      routineName: 'Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 9, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 9, 25),
      totalDurationMs: 25 * 60 * 1000,
      outcome: SessionOutcome.completed,
      routineSnapshot: routine,
    );
    final s2 = SessionRecord(
      sessionId: 's2',
      routineName: 'Focus',
      startedAtUtc: DateTime.utc(2026, 10, 16, 10, 0),
      endedAtUtc: DateTime.utc(2026, 10, 16, 10, 10),
      totalDurationMs: 10 * 60 * 1000,
      outcome: SessionOutcome.cancelled,
      routineSnapshot: routine,
    );

    when(() => mockSessionRepo.getSessionsInRange(any(), any()))
        .thenAnswer((_) async => [s1, s2]);
    when(() => mockSessionRepo.deleteSession('s1')).thenAnswer((_) async {});

    final controller = HistoryFeedController(
      sessionRepository: mockSessionRepo,
    );

    await controller.load();
    expect(controller.state.value!.length, 2);

    controller.setFilter(HistoryOutcomeFilter.completed);
    expect(controller.state.value!.length, 1);
    expect(controller.state.value!.first.sessionId, 's1');

    when(() => mockSessionRepo.getSessionsInRange(any(), any()))
        .thenAnswer((_) async => [s2]);
    await controller.deleteSession('s1');
    verify(() => mockSessionRepo.deleteSession('s1')).called(1);
  });
}
