import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/features/history/domain/analytics_models.dart';
import 'package:focus_flow/src/features/history/domain/analytics_timeframe.dart';
import 'package:focus_flow/src/features/history/presentation/widgets/summary_metric_cards.dart';

void main() {
  testWidgets('SummaryMetricCards renders total focus duration and completion metrics', (tester) async {
    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalFocusDurationMs: 90 * 60 * 1000, // 1h 30m -> 01:30:00
      completedCount: 3,
      interruptedOrCancelledCount: 1,
      dailyBuckets: const [],
      activityBreakdowns: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryMetricCards(summary: summary),
        ),
      ),
    );

    expect(find.text('Total Focus'), findsOneWidget);
    expect(find.text('01:30:00'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('3 (75%)'), findsOneWidget);
  });
}
