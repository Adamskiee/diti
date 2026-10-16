import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/features/history/domain/analytics_aggregator.dart';
import 'package:focus_flow/src/features/history/domain/analytics_timeframe.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:timer_engine/timer_engine.dart';

void main() {
  group('AnalyticsAggregator', () {
    final now = DateTime(2026, 10, 16, 14, 0); // Friday 2:00 PM local
    final range = AnalyticsTimeframe.thisWeek.computeRange(now);

    Routine createMockRoutine(String id, String name) {
      return Routine(
        id: id,
        name: name,
        repeatRule: const RepeatRule(mode: RepeatMode.count, count: 1),
        phases: const [
          RoutinePhase(
            id: 'p1',
            name: 'Focus',
            durationMs: 25 * 60 * 1000,
            transition: TransitionPolicy.auto,
          ),
        ],
      );
    }

    SessionRecord createSession({
      required String id,
      required String routineName,
      required DateTime start,
      required int durationMinutes,
      SessionOutcome outcome = SessionOutcome.completed,
      String? planBlockId,
    }) {
      final routine = createMockRoutine('r1', routineName);
      return SessionRecord(
        sessionId: id,
        routineId: 'r1',
        routineName: routineName,
        planBlockId: planBlockId,
        startedAtUtc: start.toUtc(),
        endedAtUtc: start.add(Duration(minutes: durationMinutes)).toUtc(),
        totalDurationMs: durationMinutes * 60 * 1000,
        outcome: outcome,
        routineSnapshot: routine,
      );
    }

    test('returns empty buckets when sessions list is empty', () {
      final summary = AnalyticsAggregator.computeSummary(
        sessions: [],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(summary.totalFocusDurationMs, 0);
      expect(summary.completedCount, 0);
      expect(summary.interruptedOrCancelledCount, 0);
      expect(summary.completionRate, 0.0);
      expect(summary.dailyBuckets.length, 7);
      expect(summary.activityBreakdowns, isEmpty);
      expect(summary.planVersusActual, isNull);
    });

    test('aggregates daily buckets and routine breakdowns correctly', () {
      final s1 = createSession(
        id: 's1',
        routineName: 'Deep Work',
        start: DateTime(2026, 10, 12, 10, 0), // Monday
        durationMinutes: 60,
      );
      final s2 = createSession(
        id: 's2',
        routineName: 'Deep Work',
        start: DateTime(2026, 10, 12, 14, 0), // Monday
        durationMinutes: 30,
      );
      final s3 = createSession(
        id: 's3',
        routineName: 'Reading',
        start: DateTime(2026, 10, 13, 9, 0), // Tuesday
        durationMinutes: 30,
        outcome: SessionOutcome.cancelled,
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [s1, s2, s3],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(summary.totalFocusDurationMs, (60 + 30 + 30) * 60 * 1000);
      expect(summary.completedCount, 2);
      expect(summary.interruptedOrCancelledCount, 1);
      expect(summary.completionRate, closeTo(2 / 3, 0.001));

      // Monday bucket
      final monday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Mon');
      expect(monday.totalDurationMs, 90 * 60 * 1000);
      expect(monday.sessionCount, 2);

      // Tuesday bucket
      final tuesday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Tue');
      expect(tuesday.totalDurationMs, 30 * 60 * 1000);
      expect(tuesday.sessionCount, 1);

      // Breakdown: Deep Work is 90/120 (75%), Reading is 30/120 (25%)
      expect(summary.activityBreakdowns.length, 2);
      expect(summary.activityBreakdowns[0].routineName, 'Deep Work');
      expect(summary.activityBreakdowns[0].percentage, closeTo(0.75, 0.001));
      expect(summary.activityBreakdowns[1].routineName, 'Reading');
      expect(summary.activityBreakdowns[1].percentage, closeTo(0.25, 0.001));
    });

    test('attributes session crossing midnight to local start date', () {
      final midnightSession = createSession(
        id: 's_midnight',
        routineName: 'Late Night Flow',
        start: DateTime(2026, 10, 14, 23, 45), // Wednesday 11:45 PM
        durationMinutes: 45, // Ends Thursday 12:30 AM
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [midnightSession],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      final wednesday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Wed');
      final thursday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Thu');

      expect(wednesday.totalDurationMs, 45 * 60 * 1000);
      expect(thursday.totalDurationMs, 0);
    });

    test('calculates planned vs actual metrics when linked plan blocks exist', () {
      final planBlock = PlanBlock(
        id: 'block_1',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 9, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 45 * 60 * 1000,
        actualDurationMs: 60 * 60 * 1000,
      );

      final session = createSession(
        id: 's_linked',
        routineName: 'Design Sprint',
        start: DateTime(2026, 10, 16, 9, 0),
        durationMinutes: 60,
        planBlockId: 'block_1',
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [session],
        planBlocks: [planBlock],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(summary.planVersusActual, isNotNull);
      expect(summary.planVersusActual!.totalPlannedMs, 45 * 60 * 1000);
      expect(summary.planVersusActual!.totalActualMs, 60 * 60 * 1000);
      expect(summary.planVersusActual!.netVarianceMs, 15 * 60 * 1000); // 15m overrun
      expect(summary.planVersusActual!.linkedSessionCount, 1);
    });

    test('today timeframe generates 24 hourly buckets', () {
      final todayRange = AnalyticsTimeframe.today.computeRange(now);
      final todaySession = createSession(
        id: 's_today',
        routineName: 'Morning Sprint',
        start: DateTime(2026, 10, 16, 9, 0), // 9am
        durationMinutes: 45,
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [todaySession],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.today,
        range: todayRange,
        now: now,
      );

      expect(summary.dailyBuckets.length, 24);
      final nineAmBucket = summary.dailyBuckets.firstWhere((b) => b.dayLabel == '9am');
      expect(nineAmBucket.totalDurationMs, 45 * 60 * 1000);
      expect(nineAmBucket.sessionCount, 1);
    });

    test('last30Days timeframe generates 30 daily buckets', () {
      final thirtyDaysRange = AnalyticsTimeframe.last30Days.computeRange(now);
      final summary = AnalyticsAggregator.computeSummary(
        sessions: [],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.last30Days,
        range: thirtyDaysRange,
        now: now,
      );

      expect(summary.dailyBuckets.length, 30);
    });
  });
}
