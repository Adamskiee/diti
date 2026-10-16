import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/di/repositories_provider.dart';
import 'package:focus_flow/src/features/history/presentation/history_analytics_screen.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
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

  testWidgets('HistoryAnalyticsScreen renders SegmentedButton and toggles tabs', (tester) async {
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
}
