import 'package:flutter/material.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import 'package:timer_engine/timer_engine.dart';
import 'analytics_models.dart';
import 'analytics_timeframe.dart';

/// A session's active time, split into the time spent in focus phases and
/// the time spent in rest phases.
typedef _FocusRest = ({int focusMs, int restMs});

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

    int completed = 0;
    int interruptedOrCancelled = 0;

    for (final s in filteredSessions) {
      if (s.outcome == SessionOutcome.completed) {
        completed++;
      } else {
        interruptedOrCancelled++;
      }
    }

    final totals = _sumByKind(filteredSessions);
    final totalMs = totals.focusMs + totals.restMs;

    // 2. Generate daily buckets
    final buckets = _buildBuckets(timeframe, range, filteredSessions);

    // 3. Compute activity breakdowns
    final breakdowns = _buildBreakdowns(filteredSessions, totalMs);

    // 4. Compute plan vs actual
    final planVsActual = _buildPlanVsActual(filteredSessions, planBlocks);

    return AnalyticsSummary(
      timeframe: timeframe,
      dateRange: range,
      totalDurationMs: totalMs,
      focusDurationMs: totals.focusMs,
      restDurationMs: totals.restMs,
      completedCount: completed,
      interruptedOrCancelledCount: interruptedOrCancelled,
      dailyBuckets: buckets,
      activityBreakdowns: breakdowns,
      planVersusActual: planVsActual,
    );
  }

  /// The focus and rest time of a group of sessions.
  static _FocusRest _sumByKind(List<SessionRecord> sessions) {
    int focusMs = 0;
    int restMs = 0;
    for (final s in sessions) {
      final split = _splitByKind(s);
      focusMs += split.focusMs;
      restMs += split.restMs;
    }
    return (focusMs: focusMs, restMs: restMs);
  }

  /// A session's focus and rest time, taken from its phase events.
  ///
  /// A session recorded before the per-phase breakdown existed has no events:
  /// it has no breakdown to split, so its whole duration counts as focus time
  /// and none of it as rest time. History is never reinterpreted.
  static _FocusRest _splitByKind(SessionRecord session) {
    if (session.events.isEmpty) {
      return (focusMs: session.totalDurationMs, restMs: 0);
    }

    int focusMs = 0;
    int restMs = 0;
    for (final event in session.events) {
      if (event.kind == PhaseKind.rest) {
        restMs += event.durationMs;
      } else {
        focusMs += event.durationMs;
      }
    }
    return (focusMs: focusMs, restMs: restMs);
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
        final hourSplit = _sumByKind(hourSessions);
        final label = DateFormat('ha').format(cursor).toLowerCase();

        buckets.add(
          DailyBucket(
            date: cursor,
            dayLabel: label,
            totalDurationMs: hourSplit.focusMs + hourSplit.restMs,
            focusDurationMs: hourSplit.focusMs,
            restDurationMs: hourSplit.restMs,
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
      final daySplit = _sumByKind(daySessions);

      final String label = timeframe == AnalyticsTimeframe.thisWeek
          ? DateFormat('E').format(cursor)
          : DateFormat('d').format(cursor);

      buckets.add(
        DailyBucket(
          date: cursor,
          dayLabel: label,
          totalDurationMs: daySplit.focusMs + daySplit.restMs,
          focusDurationMs: daySplit.focusMs,
          restDurationMs: daySplit.restMs,
          sessionCount: daySessions.length,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return buckets;
  }

  /// The time each routine took, as a share of the total time. The breakdown
  /// stays per-routine and unsplit: it does not separate focus from rest.
  static List<ActivityBreakdown> _buildBreakdowns(
    List<SessionRecord> sessions,
    int totalMs,
  ) {
    if (totalMs == 0 || sessions.isEmpty) return const [];

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
      final percentage = entry.value / totalMs;
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
