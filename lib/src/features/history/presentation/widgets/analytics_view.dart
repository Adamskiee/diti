import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/responsive_layout.dart';
import '../../providers/history_providers.dart';
import 'activity_breakdown_card.dart';
import 'focus_bar_chart_widget.dart';
import 'plan_vs_actual_card.dart';
import 'session_app_breakdown_card.dart';
import 'summary_metric_cards.dart';
import 'timeframe_selector_bar.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsControllerProvider);

    return Column(
      children: [
        const TimeframeSelectorBar(),
        Expanded(
          child: analyticsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error calculating analytics: $err')),
            data: (summary) {
              if (summary.totalDurationMs == 0 &&
                  summary.completedCount == 0 &&
                  summary.interruptedOrCancelledCount == 0) {
                final theme = Theme.of(context);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ResponsiveBreakpoints.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart_outlined,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activity recorded yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete your first session to view daily focus and rest hours, activity breakdowns, and performance analytics.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= ResponsiveBreakpoints.expanded;

                  if (!isWide) {
                    return ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        SummaryMetricCards(summary: summary),
                        const SizedBox(height: 16),
                        FocusBarChartWidget(buckets: summary.dailyBuckets),
                        if (summary.appUsages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SessionAppBreakdownCard(
                            usages: summary.appUsages,
                            totalDurationMs: summary.totalDurationMs,
                          ),
                        ],
                        if (summary.activityBreakdowns.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ActivityBreakdownCard(
                              breakdowns: summary.activityBreakdowns),
                        ],
                        if (summary.planVersusActual != null) ...[
                          const SizedBox(height: 16),
                          PlanVsActualCard(metrics: summary.planVersusActual!),
                        ],
                      ],
                    );
                  }

                  final leftItems = <Widget>[
                    FocusBarChartWidget(buckets: summary.dailyBuckets),
                    if (summary.planVersusActual != null) ...[
                      const SizedBox(height: 16),
                      PlanVsActualCard(metrics: summary.planVersusActual!),
                    ],
                  ];

                  final rightItems = <Widget>[
                    if (summary.activityBreakdowns.isNotEmpty)
                      ActivityBreakdownCard(
                          breakdowns: summary.activityBreakdowns),
                    if (summary.appUsages.isNotEmpty) ...[
                      if (summary.activityBreakdowns.isNotEmpty)
                        const SizedBox(height: 16),
                      SessionAppBreakdownCard(
                        usages: summary.appUsages,
                        totalDurationMs: summary.totalDurationMs,
                      ),
                    ],
                  ];

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.maxContentWidth,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 16.0),
                        children: [
                          SummaryMetricCards(summary: summary),
                          const SizedBox(height: 16),
                          if (rightItems.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: leftItems,
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: leftItems,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: rightItems,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
