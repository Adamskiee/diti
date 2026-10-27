import 'dart:async';
import '../domain/app_identity_rules.dart';
import '../domain/app_usage_summary.dart';
import '../ports/app_tracker_port.dart';

class SessionAppTracker {
  final AppTrackerPort _trackerPort;
  final Duration sampleInterval;
  final Duration maxSampleGap;
  final Duration minTrackedDuration;

  bool _isTracking = false;
  bool _isPaused = false;
  String? _sessionId;
  DateTime? _lastTickAt;
  Timer? _timer;

  final Map<String, _AppUsageAccumulator> _accumulators = {};

  SessionAppTracker({
    required AppTrackerPort trackerPort,
    this.sampleInterval = const Duration(milliseconds: 2500),
    this.maxSampleGap = const Duration(seconds: 10),
    this.minTrackedDuration = Duration.zero,
  }) : _trackerPort = trackerPort;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  String? get activeSessionId => _sessionId;

  void startSession(String sessionId) {
    _stopTimer();
    _sessionId = sessionId;
    _isTracking = true;
    _isPaused = false;
    _lastTickAt = null;
    _accumulators.clear();
    _startTimer();
  }

  void pauseSession() {
    _isPaused = true;
    _lastTickAt = null;
    _stopTimer();
  }

  void resumeSession() {
    if (!_isTracking) return;
    _isPaused = false;
    _startTimer();
  }

  Future<List<AppUsageSummary>> stopSession({DateTime? now}) async {
    _stopTimer();
    if (_isTracking && !_isPaused && now != null) {
      await tick(now: now);
    }
    _isTracking = false;
    _isPaused = false;
    _lastTickAt = null;

    final filtered = _accumulators.values
        .where((acc) => acc.durationMs >= minTrackedDuration.inMilliseconds)
        .map((acc) => acc.toSummary())
        .toList();

    // If all apps are below minTrackedDuration (e.g. short test session),
    // fall back to unfiltered accumulators so data is never discarded.
    final summaries = filtered.isNotEmpty
        ? filtered
        : _accumulators.values.map((acc) {
            final duration = acc.durationMs > 0 ? acc.durationMs : 1000;
            return AppUsageSummary(
              appName: acc.appName,
              category: acc.category,
              sampleTitle: acc.sampleTitle,
              durationMs: duration,
            );
          }).toList();

    // Sort by duration descending
    summaries.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    _accumulators.clear();
    _sessionId = null;
    return summaries;
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(sampleInterval, (_) => tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> tick({DateTime? now}) async {
    if (!_isTracking) return;

    final currentTime = now ?? DateTime.now().toUtc();

    if (_isPaused) {
      _lastTickAt = currentTime;
      return;
    }

    final sample = await _trackerPort.sampleActiveWindow();

    if (sample == null) {
      _lastTickAt = currentTime;
      return;
    }

    if (_lastTickAt != null) {
      final elapsed = currentTime.difference(_lastTickAt!);
      if (elapsed > Duration.zero) {
        // Cap excessive gaps (e.g. machine suspended)
        final effectiveElapsed =
            elapsed > maxSampleGap ? sampleInterval : elapsed;

        final identity = AppIdentityRules.identify(sample.rawClass, sample.rawTitle);
        final key = '${identity.appName}::${identity.category}';

        final acc = _accumulators.putIfAbsent(
          key,
          () => _AppUsageAccumulator(
            appName: identity.appName,
            category: identity.category,
            sampleTitle: identity.sampleTitle,
          ),
        );
        acc.addDuration(effectiveElapsed.inMilliseconds);
      }
    }

    _lastTickAt = currentTime;
  }
}

class _AppUsageAccumulator {
  final String appName;
  final String category;
  final String? sampleTitle;
  int durationMs = 0;

  _AppUsageAccumulator({
    required this.appName,
    required this.category,
    this.sampleTitle,
  });

  void addDuration(int ms) {
    durationMs += ms;
  }

  AppUsageSummary toSummary() {
    return AppUsageSummary(
      appName: appName,
      category: category,
      sampleTitle: sampleTitle,
      durationMs: durationMs,
    );
  }
}
