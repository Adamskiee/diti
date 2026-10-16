import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/history_providers.dart';
import 'activity_breakdown_card.dart';
import 'focus_bar_chart_widget.dart';
import 'plan_vs_actual_card.dart';
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
            error: (err, _) => Center(child: Text('Error calculating analytics: $err')),
            data: (summary) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  SummaryMetricCards(summary: summary),
                  const SizedBox(height: 16),
                  FocusBarChartWidget(buckets: summary.dailyBuckets),
                  if (summary.activityBreakdowns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ActivityBreakdownCard(breakdowns: summary.activityBreakdowns),
                  ],
                  if (summary.planVersusActual != null) ...[
                    const SizedBox(height: 16),
                    PlanVsActualCard(metrics: summary.planVersusActual!),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
