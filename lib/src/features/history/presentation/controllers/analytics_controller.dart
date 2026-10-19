import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../domain/analytics_aggregator.dart';
import '../../domain/analytics_models.dart';
import '../../domain/analytics_timeframe.dart';

class AnalyticsController extends StateNotifier<AsyncValue<AnalyticsSummary>> {
  final SessionRepository _sessionRepository;
  final PlanBlockRepository _planBlockRepository;
  final WallClock? _wallClock;
  AnalyticsTimeframe _timeframe;

  AnalyticsController({
    required SessionRepository sessionRepository,
    required PlanBlockRepository planBlockRepository,
    WallClock? wallClock,
    AnalyticsTimeframe initialTimeframe = AnalyticsTimeframe.thisWeek,
  })  : _sessionRepository = sessionRepository,
        _planBlockRepository = planBlockRepository,
        _wallClock = wallClock,
        _timeframe = initialTimeframe,
        super(const AsyncValue.loading()) {
    load();
  }

  AnalyticsTimeframe get timeframe => _timeframe;

  Future<void> setTimeframe(AnalyticsTimeframe timeframe) async {
    if (_timeframe == timeframe && state.hasValue) return;
    _timeframe = timeframe;
    await load();
  }

  Future<void> reload() => load();

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final now = _wallClock?.utcNow.toLocal() ?? DateTime.now();
      final range = _timeframe.computeRange(now);

      // Query sessions in range
      final sessions = await _sessionRepository.getSessionsInRange(
        range.start.toUtc(),
        range.end.toUtc(),
      );

      // Gather plan blocks for dates in range in parallel
      final dateKeys = <String>[];
      DateTime cursor = range.start;
      while (cursor.isBefore(range.end)) {
        dateKeys.add(DateFormat('yyyy-MM-dd').format(cursor));
        cursor = cursor.add(const Duration(days: 1));
      }

      final blockLists = await Future.wait(
        dateKeys.map((k) => _planBlockRepository.getBlocksForDate(k)),
      );
      final planBlocks = blockLists.expand((b) => b).toList();

      final summary = AnalyticsAggregator.computeSummary(
        sessions: sessions,
        planBlocks: planBlocks,
        timeframe: _timeframe,
        range: range,
        now: now,
      );

      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
