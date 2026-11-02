import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/theme/responsive_layout.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/domain/analytics_timeframe.dart';
import 'package:diti/src/features/history/presentation/controllers/analytics_controller.dart';
import 'package:diti/src/features/history/presentation/widgets/activity_breakdown_card.dart';
import 'package:diti/src/features/history/presentation/widgets/analytics_view.dart';
import 'package:diti/src/features/history/presentation/widgets/focus_bar_chart_widget.dart';
import 'package:diti/src/features/history/presentation/widgets/plan_vs_actual_card.dart';
import 'package:diti/src/features/history/presentation/widgets/session_app_breakdown_card.dart';
import 'package:diti/src/features/history/presentation/widgets/summary_metric_cards.dart';
import 'package:diti/src/features/history/providers/history_providers.dart';
import 'package:diti_tracker/diti_tracker.dart';

class _FakeAnalyticsController
    extends StateNotifier<AsyncValue<AnalyticsSummary>>
    implements AnalyticsController {
  _FakeAnalyticsController(AnalyticsSummary summary)
      : super(AsyncValue.data(summary));

  @override
  AnalyticsTimeframe get timeframe => AnalyticsTimeframe.thisWeek;

  @override
  Future<void> setTimeframe(AnalyticsTimeframe timeframe) async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> load() async {}
}

void main() {
  AnalyticsSummary createMockSummary({
    bool withBreakdowns = true,
  }) {
    return AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 90 * 60 * 1000,
      focusDurationMs: 60 * 60 * 1000,
      restDurationMs: 30 * 60 * 1000,
      completedCount: 3,
      interruptedOrCancelledCount: 1,
      dailyBuckets: [
        DailyBucket(
          date: DateTime(2026, 10, 12),
          dayLabel: 'Mon',
          focusDurationMs: 60 * 60 * 1000,
          restDurationMs: 30 * 60 * 1000,
          totalDurationMs: 90 * 60 * 1000,
          sessionCount: 1,
        ),
      ],
      activityBreakdowns: withBreakdowns
          ? [
              const ActivityBreakdown(
                routineName: 'Deep Work',
                totalDurationMs: 60 * 60 * 1000,
                percentage: 0.67,
                color: Colors.blue,
              ),
            ]
          : const [],
      appUsages: withBreakdowns
          ? [
              const AppUsageSummary(
                appName: 'VS Code',
                category: 'development',
                durationMs: 45 * 60 * 1000,
              ),
            ]
          : const [],
      planVersusActual: const PlanVersusActualMetrics(
        totalPlannedMs: 60 * 60 * 1000,
        totalActualMs: 60 * 60 * 1000,
        netVarianceMs: 0,
        linkedSessionCount: 1,
      ),
    );
  }

  Widget createSubject(AnalyticsSummary summary) {
    return ProviderScope(
      overrides: [
        analyticsControllerProvider.overrideWith(
          (ref) => _FakeAnalyticsController(summary),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: AnalyticsView(),
        ),
      ),
    );
  }

  testWidgets('renders single vertical column on compact screen (< 840dp)',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = createMockSummary(withBreakdowns: true);
    await tester.pumpWidget(createSubject(summary));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryMetricCards), findsOneWidget);
    expect(find.byType(FocusBarChartWidget), findsOneWidget);
    expect(find.byType(SessionAppBreakdownCard), findsOneWidget);
    expect(find.byType(ActivityBreakdownCard), findsOneWidget);
    expect(find.byType(PlanVsActualCard), findsOneWidget);

    // On compact screen, there is no Row containing dual Expanded columns.
    final dualColumnRows = tester.widgetList<Row>(find.byType(Row)).where(
          (r) =>
              r.crossAxisAlignment == CrossAxisAlignment.start &&
              r.children.whereType<Expanded>().length == 2,
        );
    expect(dualColumnRows, isEmpty);
  });

  testWidgets(
      'renders dual-column layout on wide screen (>= 840dp) when right items exist',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = createMockSummary(withBreakdowns: true);
    await tester.pumpWidget(createSubject(summary));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryMetricCards), findsOneWidget);
    expect(find.byType(FocusBarChartWidget), findsOneWidget);
    expect(find.byType(ActivityBreakdownCard), findsOneWidget);

    // On wide screen, dual-column Row is rendered with 2 Expanded children.
    final dualColumnRows = tester.widgetList<Row>(find.byType(Row)).where(
          (r) =>
              r.crossAxisAlignment == CrossAxisAlignment.start &&
              r.children.whereType<Expanded>().length == 2,
        );
    expect(dualColumnRows, hasLength(1));
  });

  testWidgets(
      'falls back to full-width left column when right items are empty on wide screen',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final summary = createMockSummary(withBreakdowns: false);
    await tester.pumpWidget(createSubject(summary));
    await tester.pumpAndSettle();

    expect(find.byType(FocusBarChartWidget), findsOneWidget);
    expect(find.byType(ActivityBreakdownCard), findsNothing);
    expect(find.byType(SessionAppBreakdownCard), findsNothing);

    // Dynamic fallback: No dual-column Row is rendered; left column items span full width.
    final dualColumnRows = tester.widgetList<Row>(find.byType(Row)).where(
          (r) =>
              r.crossAxisAlignment == CrossAxisAlignment.start &&
              r.children.whereType<Expanded>().length == 2,
        );
    expect(dualColumnRows, isEmpty);
  });

  testWidgets('centers empty state inside max-width container on wide screen',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final emptySummary = AnalyticsSummary(
      timeframe: AnalyticsTimeframe.thisWeek,
      dateRange: DateTimeRange(
        start: DateTime(2026, 10, 12),
        end: DateTime(2026, 10, 18),
      ),
      totalDurationMs: 0,
      focusDurationMs: 0,
      restDurationMs: 0,
      completedCount: 0,
      interruptedOrCancelledCount: 0,
      dailyBuckets: const [],
      activityBreakdowns: const [],
    );

    await tester.pumpWidget(createSubject(emptySummary));
    await tester.pumpAndSettle();

    expect(find.text('No activity recorded yet'), findsOneWidget);
    final emptyBox = tester.widget<ConstrainedBox>(
      find
          .ancestor(
            of: find.text('No activity recorded yet'),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(
        emptyBox.constraints.maxWidth, ResponsiveBreakpoints.maxContentWidth);
  });
}
