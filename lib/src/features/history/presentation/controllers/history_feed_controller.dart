import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import '../../providers/history_providers.dart';

class HistoryFeedController
    extends StateNotifier<AsyncValue<List<SessionRecord>>> {
  final SessionRepository _sessionRepository;
  HistoryOutcomeFilter _filter;
  List<SessionRecord> _allSessions = const [];

  HistoryFeedController({
    required SessionRepository sessionRepository,
    HistoryOutcomeFilter initialFilter = HistoryOutcomeFilter.all,
  })  : _sessionRepository = sessionRepository,
        _filter = initialFilter,
        super(const AsyncValue.loading()) {
    load();
  }

  HistoryOutcomeFilter get filter => _filter;

  void setFilter(HistoryOutcomeFilter filter) {
    _filter = filter;
    _applyFilter();
  }

  Future<void> reload() => load();

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      // Query recent sessions (last 90 days)
      final end = DateTime.now().toUtc().add(const Duration(days: 1));
      final start = end.subtract(const Duration(days: 90));
      _allSessions = await _sessionRepository.getSessionsInRange(start, end);

      // Sort descending by start time
      _allSessions.sort((a, b) => b.startedAtUtc.compareTo(a.startedAtUtc));

      if (!mounted) return;
      _applyFilter();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  void _applyFilter() {
    switch (_filter) {
      case HistoryOutcomeFilter.all:
        state = AsyncValue.data(List.unmodifiable(_allSessions));
        break;
      case HistoryOutcomeFilter.completed:
        state = AsyncValue.data(
          _allSessions
              .where((s) => s.outcome == SessionOutcome.completed)
              .toList(),
        );
        break;
      case HistoryOutcomeFilter.interruptedOrCancelled:
        state = AsyncValue.data(
          _allSessions
              .where((s) => s.outcome != SessionOutcome.completed)
              .toList(),
        );
        break;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionRepository.deleteSession(sessionId);
    await load();
  }
}
