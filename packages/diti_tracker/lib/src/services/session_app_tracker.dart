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
  Future<void>? _initialSampleFuture;

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

  void startSession(String sessionId, {DateTime? now}) {
    _stopTimer();
    _sessionId = sessionId;
    _isTracking = true;
    _isPaused = false;
    _accumulators.clear();
    final startTime = now ?? DateTime.now().toUtc();
    _lastTickAt = startTime;
    _startTimer();
    _initialSampleFuture = _sampleInitial(startTime);
  }

  Future<void> _sampleInitial(DateTime startTime) async {
    if (!_isTracking || _isPaused) return;
    final sample = await _trackerPort.sampleActiveWindow();
    if (sample == null || !_isTracking || _isPaused) return;
    final identity =
        AppIdentityRules.identify(sample.rawClass, sample.rawTitle);
    final key = '${identity.appName}::${identity.category}';
    _accumulators.putIfAbsent(
      key,
      () => _AppUsageAccumulator(
        appName: identity.appName,
        category: identity.category,
        sampleTitle: identity.sampleTitle,
      ),
    );
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

    if (_initialSampleFuture != null) {
      try {
        await _initialSampleFuture;
      } catch (_) {}
    }

    if (_isTracking && !_isPaused) {
      if (now != null) {
        await tick(now: now);
      } else if (_lastTickAt != null) {
        final currentWall = DateTime.now().toUtc();
        final diff = currentWall.difference(_lastTickAt!);
        if (diff >= Duration.zero && diff <= maxSampleGap) {
          await tick(now: currentWall);
        }
      }
    }

    _isTracking = false;
    _isPaused = false;
    _lastTickAt = null;
    _initialSampleFuture = null;

    final nonZeroAccumulators =
        _accumulators.values.where((acc) => acc.durationMs > 0).toList();

    final filtered = nonZeroAccumulators
        .where((acc) => acc.durationMs >= minTrackedDuration.inMilliseconds)
        .map((acc) => acc.toSummary())
        .toList();

    // If all apps are below minTrackedDuration (e.g. short test session),
    // fall back to unfiltered accumulators so data is never discarded.
    final summaries = filtered.isNotEmpty
        ? filtered
        : nonZeroAccumulators.map((acc) => acc.toSummary()).toList();

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

        final activeSample = sample;
        final identity = AppIdentityRules.identify(
            activeSample.rawClass, activeSample.rawTitle);
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
