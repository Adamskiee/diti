import 'package:flutter/material.dart';
import 'analytics_timeframe.dart';

class DailyBucket {
  final DateTime date;
  final String dayLabel;
  final int totalDurationMs;
  final int sessionCount;

  const DailyBucket({
    required this.date,
    required this.dayLabel,
    required this.totalDurationMs,
    required this.sessionCount,
  });
}

class ActivityBreakdown {
  final String routineName;
  final int totalDurationMs;
  final double percentage; // 0.0 to 1.0
  final Color color;

  const ActivityBreakdown({
    required this.routineName,
    required this.totalDurationMs,
    required this.percentage,
    required this.color,
  });
}

class PlanVersusActualMetrics {
  final int totalPlannedMs;
  final int totalActualMs;
  final int netVarianceMs;
  final int linkedSessionCount;

  const PlanVersusActualMetrics({
    required this.totalPlannedMs,
    required this.totalActualMs,
    required this.netVarianceMs,
    required this.linkedSessionCount,
  });
}

class AnalyticsSummary {
  final AnalyticsTimeframe timeframe;
  final DateTimeRange dateRange;
  final int totalFocusDurationMs;
  final int completedCount;
  final int interruptedOrCancelledCount;
  final List<DailyBucket> dailyBuckets;
  final List<ActivityBreakdown> activityBreakdowns;
  final PlanVersusActualMetrics? planVersusActual;

  const AnalyticsSummary({
    required this.timeframe,
    required this.dateRange,
    required this.totalFocusDurationMs,
    required this.completedCount,
    required this.interruptedOrCancelledCount,
    required this.dailyBuckets,
    required this.activityBreakdowns,
    this.planVersusActual,
  });

  double get completionRate => (completedCount + interruptedOrCancelledCount) == 0
      ? 0.0
      : completedCount / (completedCount + interruptedOrCancelledCount);
}
