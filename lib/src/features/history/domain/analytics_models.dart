import 'package:flutter/material.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'analytics_timeframe.dart';

class DailyBucket {
  final DateTime date;
  final String dayLabel;

  /// All the active time of the bucket: focus time plus rest time.
  final int totalDurationMs;

  /// The part of [totalDurationMs] spent in focus phases.
  final int focusDurationMs;

  /// The part of [totalDurationMs] spent in rest phases.
  final int restDurationMs;
  final int sessionCount;

  const DailyBucket({
    required this.date,
    required this.dayLabel,
    required this.totalDurationMs,
    required this.focusDurationMs,
    required this.restDurationMs,
    required this.sessionCount,
  });
}

class ActivityBreakdown {
  final String routineName;
  final int totalDurationMs;
  final double percentage; // 0.0 to 1.0
  final Color color;
  final List<SessionRecord> sessions;

  const ActivityBreakdown({
    required this.routineName,
    required this.totalDurationMs,
    required this.percentage,
    required this.color,
    this.sessions = const [],
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

  /// All the active time of the timeframe: focus time plus rest time.
  final int totalDurationMs;

  /// The part of [totalDurationMs] spent in focus phases.
  final int focusDurationMs;

  /// The part of [totalDurationMs] spent in rest phases.
  final int restDurationMs;
  final int completedCount;
  final int interruptedOrCancelledCount;
  final List<DailyBucket> dailyBuckets;
  final List<ActivityBreakdown> activityBreakdowns;
  final PlanVersusActualMetrics? planVersusActual;
  final List<AppUsageSummary> appUsages;

  const AnalyticsSummary({
    required this.timeframe,
    required this.dateRange,
    required this.totalDurationMs,
    required this.focusDurationMs,
    required this.restDurationMs,
    required this.completedCount,
    required this.interruptedOrCancelledCount,
    required this.dailyBuckets,
    required this.activityBreakdowns,
    this.planVersusActual,
    this.appUsages = const [],
  });

  double get completionRate =>
      (completedCount + interruptedOrCancelledCount) == 0
          ? 0.0
          : completedCount / (completedCount + interruptedOrCancelledCount);
}
