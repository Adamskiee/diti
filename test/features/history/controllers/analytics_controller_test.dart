import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/features/history/domain/analytics_timeframe.dart';
import 'package:focus_flow/src/features/history/presentation/controllers/analytics_controller.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}
class MockPlanBlockRepository extends Mock implements PlanBlockRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026, 10, 14));
  });

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

  test('AnalyticsController loads summary and responds to timeframe changes', () async {
    final controller = AnalyticsController(
      sessionRepository: mockSessionRepo,
      planBlockRepository: mockPlanBlockRepo,
      initialTimeframe: AnalyticsTimeframe.thisWeek,
    );

    await controller.load();
    expect(controller.state.hasValue, isTrue);
    expect(controller.state.value!.timeframe, AnalyticsTimeframe.thisWeek);

    await controller.setTimeframe(AnalyticsTimeframe.today);
    expect(controller.state.value!.timeframe, AnalyticsTimeframe.today);
  });
}
