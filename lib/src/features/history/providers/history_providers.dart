import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import '../../../core/di/repositories_provider.dart';
import '../domain/analytics_models.dart';
import '../domain/analytics_timeframe.dart';
import '../presentation/controllers/analytics_controller.dart';
import '../presentation/controllers/history_feed_controller.dart';

enum HistoryTab {
  analytics,
  history,
}

enum HistoryOutcomeFilter {
  all,
  completed,
  interruptedOrCancelled,
}

final historyActiveTabProvider =
    StateProvider<HistoryTab>((ref) => HistoryTab.analytics);

final analyticsTimeframeProvider =
    StateProvider<AnalyticsTimeframe>((ref) => AnalyticsTimeframe.thisWeek);

final historyFeedFilterProvider =
    StateProvider<HistoryOutcomeFilter>((ref) => HistoryOutcomeFilter.all);

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AsyncValue<AnalyticsSummary>>(
        (ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final planBlockRepo = ref.watch(planBlockRepositoryProvider);
  final timeframe = ref.watch(analyticsTimeframeProvider);
  return AnalyticsController(
    sessionRepository: sessionRepo,
    planBlockRepository: planBlockRepo,
    initialTimeframe: timeframe,
  );
});

final historyFeedControllerProvider =
    StateNotifierProvider<HistoryFeedController, AsyncValue<List<SessionRecord>>>(
        (ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final filter = ref.watch(historyFeedFilterProvider);
  return HistoryFeedController(
    sessionRepository: sessionRepo,
    initialFilter: filter,
  );
});
