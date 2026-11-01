import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/domain/analytics_timeframe.dart';
import 'package:diti/src/features/history/presentation/widgets/summary_metric_cards.dart';

void main() {
  testWidgets('SummaryMetricCards renders total duration and completion metrics', (tester) async {
    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 90 * 60 * 1000, // 1h 30m -> 01:30:00
      focusDurationMs: 60 * 60 * 1000, // 01:00:00
      restDurationMs: 30 * 60 * 1000, // 30:00
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

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('01:30:00'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('3 (75%)'), findsOneWidget);
  });

  testWidgets('shows Total, Focus, Rest and Completed', (tester) async {
    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 30 * 60 * 1000, // 30:00
      focusDurationMs: 25 * 60 * 1000, // 25:00
      restDurationMs: 5 * 60 * 1000, // 05:00
      completedCount: 1,
      interruptedOrCancelledCount: 0,
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

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    expect(find.text('30:00'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('1 (100%)'), findsOneWidget);
  });

  testWidgets('never labels a duration that includes rest as focus', (tester) async {
    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 30 * 60 * 1000,
      focusDurationMs: 25 * 60 * 1000,
      restDurationMs: 5 * 60 * 1000,
      completedCount: 1,
      interruptedOrCancelledCount: 0,
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

    // The total includes the rest time, so it must not be called "focus".
    expect(find.text('Total Focus'), findsNothing);
  });

  testWidgets('lays out without overflowing on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 30 * 60 * 1000,
      focusDurationMs: 25 * 60 * 1000,
      restDurationMs: 5 * 60 * 1000,
      completedCount: 1,
      interruptedOrCancelledCount: 0,
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

    expect(tester.takeException(), isNull);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('the tiles follow the app\'s focus and rest colour convention', (tester) async {
    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 30 * 60 * 1000,
      focusDurationMs: 25 * 60 * 1000,
      restDurationMs: 5 * 60 * 1000,
      completedCount: 1,
      interruptedOrCancelledCount: 0,
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

    // Focus is the primary colour and rest is the tertiary one, exactly as the
    // phase chips on the verification sheet render them, so one colour never
    // means two things on the same screen.
    final theme = Theme.of(tester.element(find.byType(SummaryMetricCards)));
    final totalIcon = tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
    final focusIcon = tester.widget<Icon>(find.byIcon(Icons.bolt_outlined));
    final restIcon =
        tester.widget<Icon>(find.byIcon(Icons.self_improvement_outlined));

    expect(totalIcon.color, theme.colorScheme.secondary);
    expect(focusIcon.color, theme.colorScheme.primary);
    expect(restIcon.color, theme.colorScheme.tertiary);
  });

  testWidgets('renders 1x4 row on wide screens (>= 840dp)', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 60 * 60 * 1000,
      focusDurationMs: 45 * 60 * 1000,
      restDurationMs: 15 * 60 * 1000,
      completedCount: 2,
      interruptedOrCancelledCount: 0,
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
    await tester.pumpAndSettle();

    // On wide screen (>= 840dp), all 4 metric cards are in a single horizontal Row.
    // The top-level layout Row for the 4 metric cards contains 4 Expanded children.
    final rows = tester.widgetList<Row>(find.descendant(
      of: find.byType(SummaryMetricCards),
      matching: find.byType(Row),
    ));

    final wideLayoutRow = rows.where((r) => r.children.whereType<Expanded>().length == 4);
    expect(wideLayoutRow, hasLength(1));
  });

  testWidgets('renders 2x2 grid on compact screens (< 840dp)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 60 * 60 * 1000,
      focusDurationMs: 45 * 60 * 1000,
      restDurationMs: 15 * 60 * 1000,
      completedCount: 2,
      interruptedOrCancelledCount: 0,
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
    await tester.pumpAndSettle();

    // On compact screen (< 840dp), 2 layout Rows with 2 Expanded children each.
    final rows = tester.widgetList<Row>(find.descendant(
      of: find.byType(SummaryMetricCards),
      matching: find.byType(Row),
    ));

    final compactLayoutRows = rows.where((r) => r.children.whereType<Expanded>().length == 2);
    expect(compactLayoutRows, hasLength(2));
  });
}
