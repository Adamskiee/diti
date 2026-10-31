import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_aggregator.dart';
import 'package:diti/src/features/history/domain/analytics_timeframe.dart';
import 'package:diti_database/diti_database.dart';
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
      List<SessionEventRecord> events = const [],
      List<SessionAppUsageRecord> appUsages = const [],
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
        events: events,
        appUsages: appUsages,
      );
    }

    /// One phase event, the way the app stores a phase's active time.
    SessionEventRecord createPhaseEvent({
      required String sessionId,
      required String phaseName,
      required int durationMinutes,
      required PhaseKind kind,
    }) {
      return SessionEventRecord(
        eventId: 'evt_${sessionId}_$phaseName',
        sessionId: sessionId,
        eventType: 'phase_finished',
        occurredAtUtc: DateTime.utc(2026, 10, 12, 10, 0),
        phaseId: 'phase_$phaseName',
        phaseName: phaseName,
        durationMs: durationMinutes * 60 * 1000,
        outcome: 'completed',
        kind: kind,
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

      expect(summary.totalDurationMs, 0);
      expect(summary.focusDurationMs, 0);
      expect(summary.restDurationMs, 0);
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

      expect(summary.totalDurationMs, (60 + 30 + 30) * 60 * 1000);
      expect(summary.focusDurationMs, (60 + 30 + 30) * 60 * 1000);
      expect(summary.restDurationMs, 0);
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
      expect(summary.activityBreakdowns[0].sessions.map((s) => s.sessionId), ['s2', 's1']);
      expect(summary.activityBreakdowns[1].routineName, 'Reading');
      expect(summary.activityBreakdowns[1].percentage, closeTo(0.25, 0.001));
      expect(summary.activityBreakdowns[1].sessions.map((s) => s.sessionId), ['s3']);
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

    test('splits a multi-phase session into focus and rest', () {
      final session = createSession(
        id: 's_split',
        routineName: 'Pomodoro',
        start: DateTime(2026, 10, 12, 10, 0), // Monday
        durationMinutes: 30,
        events: [
          createPhaseEvent(
            sessionId: 's_split',
            phaseName: 'Focus',
            durationMinutes: 25,
            kind: PhaseKind.focus,
          ),
          createPhaseEvent(
            sessionId: 's_split',
            phaseName: 'Break',
            durationMinutes: 5,
            kind: PhaseKind.rest,
          ),
        ],
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [session],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(summary.totalDurationMs, 1800000);
      expect(summary.focusDurationMs, 1500000);
      expect(summary.restDurationMs, 300000);
    });

    test('a session with no events counts entirely as focus', () {
      // A session recorded before the per-phase breakdown existed: it has no
      // events, so its whole duration is focus and nothing is rest.
      final session = createSession(
        id: 's_without_events',
        routineName: 'Deep Work',
        start: DateTime(2026, 10, 12, 10, 0), // Monday
        durationMinutes: 25,
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [session],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(summary.focusDurationMs, 1500000);
      expect(summary.restDurationMs, 0);
      expect(summary.totalDurationMs, 1500000);
    });

    test('the total always equals focus plus rest', () {
      final sessions = [
        createSession(
          id: 's_mixed_split',
          routineName: 'Pomodoro',
          start: DateTime(2026, 10, 12, 10, 0), // Monday
          durationMinutes: 30,
          events: [
            createPhaseEvent(
              sessionId: 's_mixed_split',
              phaseName: 'Focus',
              durationMinutes: 25,
              kind: PhaseKind.focus,
            ),
            createPhaseEvent(
              sessionId: 's_mixed_split',
              phaseName: 'Break',
              durationMinutes: 5,
              kind: PhaseKind.rest,
            ),
          ],
        ),
        createSession(
          id: 's_mixed_legacy',
          routineName: 'Deep Work',
          start: DateTime(2026, 10, 13, 9, 0), // Tuesday, no events
          durationMinutes: 45,
        ),
        createSession(
          id: 's_mixed_rest_only',
          routineName: 'Reading',
          start: DateTime(2026, 10, 14, 9, 0), // Wednesday, rest only
          durationMinutes: 10,
          events: [
            createPhaseEvent(
              sessionId: 's_mixed_rest_only',
              phaseName: 'Cooldown',
              durationMinutes: 10,
              kind: PhaseKind.rest,
            ),
          ],
        ),
      ];

      final summary = AnalyticsAggregator.computeSummary(
        sessions: sessions,
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(
        summary.totalDurationMs,
        summary.focusDurationMs + summary.restDurationMs,
      );
      expect(summary.totalDurationMs, (30 + 45 + 10) * 60 * 1000);
      expect(summary.focusDurationMs, (25 + 45) * 60 * 1000);
      expect(summary.restDurationMs, (5 + 10) * 60 * 1000);
    });

    test('daily buckets split focus and rest', () {
      final sessions = [
        createSession(
          id: 's_bucket_split',
          routineName: 'Pomodoro',
          start: DateTime(2026, 10, 12, 10, 0), // Monday
          durationMinutes: 30,
          events: [
            createPhaseEvent(
              sessionId: 's_bucket_split',
              phaseName: 'Focus',
              durationMinutes: 25,
              kind: PhaseKind.focus,
            ),
            createPhaseEvent(
              sessionId: 's_bucket_split',
              phaseName: 'Break',
              durationMinutes: 5,
              kind: PhaseKind.rest,
            ),
          ],
        ),
        createSession(
          id: 's_bucket_legacy',
          routineName: 'Deep Work',
          start: DateTime(2026, 10, 12, 15, 0), // Monday, no events
          durationMinutes: 20,
        ),
      ];

      final summary = AnalyticsAggregator.computeSummary(
        sessions: sessions,
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      final monday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Mon');
      expect(monday.focusDurationMs, (25 + 20) * 60 * 1000);
      expect(monday.restDurationMs, 5 * 60 * 1000);
      expect(
        monday.totalDurationMs,
        monday.focusDurationMs + monday.restDurationMs,
      );

      for (final bucket in summary.dailyBuckets) {
        expect(
          bucket.totalDurationMs,
          bucket.focusDurationMs + bucket.restDurationMs,
          reason: 'bucket ${bucket.dayLabel} must split cleanly',
        );
      }
    });

    test('a session crossing midnight is attributed to its start date', () {
      final session = createSession(
        id: 's_midnight_split',
        routineName: 'Late Night Flow',
        start: DateTime(2026, 10, 14, 23, 50), // Wednesday 11:50 PM
        durationMinutes: 30, // Ends Thursday 12:20 AM
        events: [
          createPhaseEvent(
            sessionId: 's_midnight_split',
            phaseName: 'Focus',
            durationMinutes: 20,
            kind: PhaseKind.focus,
          ),
          createPhaseEvent(
            sessionId: 's_midnight_split',
            phaseName: 'Break',
            durationMinutes: 10,
            kind: PhaseKind.rest,
          ),
        ],
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [session],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      final wednesday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Wed');
      final thursday = summary.dailyBuckets.firstWhere((b) => b.dayLabel == 'Thu');

      expect(wednesday.totalDurationMs, 30 * 60 * 1000);
      expect(wednesday.focusDurationMs, 20 * 60 * 1000);
      expect(wednesday.restDurationMs, 10 * 60 * 1000);
      expect(thursday.totalDurationMs, 0);
      expect(thursday.focusDurationMs, 0);
      expect(thursday.restDurationMs, 0);
    });

    test('aggregates appUsages across sessions in timeframe, summing durations and sorting descending', () {
      final session1 = createSession(
        id: 's1',
        routineName: 'Coding',
        start: DateTime(2026, 10, 14, 10, 0),
        durationMinutes: 30,
        appUsages: const [
          SessionAppUsageRecord(
            id: 'u1',
            sessionId: 's1',
            appName: 'VS Code',
            category: 'Development',
            sampleTitle: 'main.dart',
            durationMs: 1200000, // 20m
          ),
          SessionAppUsageRecord(
            id: 'u2',
            sessionId: 's1',
            appName: 'Terminal',
            category: 'Terminal',
            sampleTitle: 'bash',
            durationMs: 600000, // 10m
          ),
        ],
      );

      final session2 = createSession(
        id: 's2',
        routineName: 'Research',
        start: DateTime(2026, 10, 15, 14, 0),
        durationMinutes: 40,
        appUsages: const [
          SessionAppUsageRecord(
            id: 'u3',
            sessionId: 's2',
            appName: 'Brave',
            category: 'YouTube',
            sampleTitle: 'Tutorial - YouTube',
            durationMs: 1800000, // 30m
          ),
          SessionAppUsageRecord(
            id: 'u4',
            sessionId: 's2',
            appName: 'VS Code',
            category: 'Development',
            sampleTitle: 'test.dart',
            durationMs: 600000, // 10m
          ),
        ],
      );

      final summary = AnalyticsAggregator.computeSummary(
        sessions: [session1, session2],
        planBlocks: [],
        timeframe: AnalyticsTimeframe.thisWeek,
        range: range,
        now: now,
      );

      expect(summary.appUsages.length, equals(3));
      // 1st: VS Code (1200000 + 600000 = 1800000ms)
      // 2nd: Brave YouTube (1800000ms)
      // 3rd: Terminal (600000ms)
      final vsCode = summary.appUsages.firstWhere((u) => u.appName == 'VS Code');
      expect(vsCode.durationMs, equals(1800000));
      expect(vsCode.category, equals('Development'));

      final youtube = summary.appUsages.firstWhere((u) => u.category == 'YouTube');
      expect(youtube.durationMs, equals(1800000));
      expect(youtube.appName, equals('Brave'));

      final terminal = summary.appUsages.firstWhere((u) => u.category == 'Terminal');
      expect(terminal.durationMs, equals(600000));

      expect(summary.appUsages.last.appName, equals('Terminal'));
    });
  });
}
