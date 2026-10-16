import 'package:flutter/material.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:intl/intl.dart';
import 'analytics_models.dart';
import 'analytics_timeframe.dart';

class AnalyticsAggregator {
  static const List<Color> _palette = [
    Color(0xFF6750A4), // Primary Purple
    Color(0xFF006C50), // Teal
    Color(0xFF984061), // Rose
    Color(0xFF7D5260), // Mauve
    Color(0xFF006874), // Cyan
    Color(0xFF825500), // Amber
    Color(0xFF4C662B), // Olive
  ];

  static AnalyticsSummary computeSummary({
    required List<SessionRecord> sessions,
    List<PlanBlock>? planBlocks,
    required AnalyticsTimeframe timeframe,
    required DateTimeRange range,
    required DateTime now,
  }) {
    // 1. Filter sessions falling into [range.start, range.end)
    final filteredSessions = sessions.where((s) {
      final startLocal = s.startedAtUtc.toLocal();
      return !startLocal.isBefore(range.start) && startLocal.isBefore(range.end);
    }).toList();

    int totalFocusMs = 0;
    int completed = 0;
    int interruptedOrCancelled = 0;

    for (final s in filteredSessions) {
      totalFocusMs += s.totalDurationMs;
      if (s.outcome == SessionOutcome.completed) {
        completed++;
      } else {
        interruptedOrCancelled++;
      }
    }

    // 2. Generate daily buckets
    final buckets = _buildBuckets(timeframe, range, filteredSessions);

    // 3. Compute activity breakdowns
    final breakdowns = _buildBreakdowns(filteredSessions, totalFocusMs);

    // 4. Compute plan vs actual
    final planVsActual = _buildPlanVsActual(filteredSessions, planBlocks);

    return AnalyticsSummary(
      timeframe: timeframe,
      dateRange: range,
      totalFocusDurationMs: totalFocusMs,
      completedCount: completed,
      interruptedOrCancelledCount: interruptedOrCancelled,
      dailyBuckets: buckets,
      activityBreakdowns: breakdowns,
      planVersusActual: planVsActual,
    );
  }

  static List<DailyBucket> _buildBuckets(
    AnalyticsTimeframe timeframe,
    DateTimeRange range,
    List<SessionRecord> sessions,
  ) {
    if (timeframe == AnalyticsTimeframe.today) {
      final Map<String, List<SessionRecord>> grouped = {};
      for (final s in sessions) {
        final localStart = s.startedAtUtc.toLocal();
        final key = DateFormat('yyyy-MM-dd HH').format(localStart);
        grouped.putIfAbsent(key, () => []).add(s);
      }

      final buckets = <DailyBucket>[];
      DateTime cursor = range.start;

      while (cursor.isBefore(range.end)) {
        final key = DateFormat('yyyy-MM-dd HH').format(cursor);
        final hourSessions = grouped[key] ?? [];
        final hourDuration = hourSessions.fold<int>(0, (sum, s) => sum + s.totalDurationMs);
        final label = DateFormat('ha').format(cursor).toLowerCase();

        buckets.add(
          DailyBucket(
            date: cursor,
            dayLabel: label,
            totalDurationMs: hourDuration,
            sessionCount: hourSessions.length,
          ),
        );

        cursor = cursor.add(const Duration(hours: 1));
      }

      return buckets;
    }

    final Map<String, List<SessionRecord>> grouped = {};
    for (final s in sessions) {
      final localStart = s.startedAtUtc.toLocal();
      final key = DateFormat('yyyy-MM-dd').format(localStart);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    final buckets = <DailyBucket>[];
    DateTime cursor = range.start;

    while (cursor.isBefore(range.end)) {
      final key = DateFormat('yyyy-MM-dd').format(cursor);
      final daySessions = grouped[key] ?? [];
      final dayDuration = daySessions.fold<int>(0, (sum, s) => sum + s.totalDurationMs);

      final String label = timeframe == AnalyticsTimeframe.thisWeek
          ? DateFormat('E').format(cursor)
          : DateFormat('d').format(cursor);

      buckets.add(
        DailyBucket(
          date: cursor,
          dayLabel: label,
          totalDurationMs: dayDuration,
          sessionCount: daySessions.length,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return buckets;
  }

  static List<ActivityBreakdown> _buildBreakdowns(
    List<SessionRecord> sessions,
    int totalFocusMs,
  ) {
    if (totalFocusMs == 0 || sessions.isEmpty) return const [];

    final Map<String, int> durationByRoutine = {};
    for (final s in sessions) {
      final name = s.routineName.trim().isEmpty ? 'Quick Timer' : s.routineName;
      durationByRoutine[name] = (durationByRoutine[name] ?? 0) + s.totalDurationMs;
    }

    final sortedEntries = durationByRoutine.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final breakdowns = <ActivityBreakdown>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = _palette[i % _palette.length];
      final percentage = entry.value / totalFocusMs;
      breakdowns.add(
        ActivityBreakdown(
          routineName: entry.key,
          totalDurationMs: entry.value,
          percentage: percentage,
          color: color,
        ),
      );
    }

    return breakdowns;
  }

  static PlanVersusActualMetrics? _buildPlanVsActual(
    List<SessionRecord> sessions,
    List<PlanBlock>? planBlocks,
  ) {
    if (planBlocks == null || planBlocks.isEmpty) return null;

    final blockMap = {for (final b in planBlocks) b.id: b};
    int totalPlanned = 0;
    int totalActual = 0;
    int count = 0;

    for (final s in sessions) {
      if (s.planBlockId != null && blockMap.containsKey(s.planBlockId)) {
        final block = blockMap[s.planBlockId]!;
        totalPlanned += block.plannedDurationMs;
        totalActual += s.totalDurationMs;
        count++;
      }
    }

    if (count == 0) return null;

    return PlanVersusActualMetrics(
      totalPlannedMs: totalPlanned,
      totalActualMs: totalActual,
      netVarianceMs: totalActual - totalPlanned,
      linkedSessionCount: count,
    );
  }
}
