import 'dart:async';
import '../domain/app_identity_rules.dart';
import '../ports/app_tracker_port.dart';

typedef OnActivitySample = Future<void> Function(
  DateTime sampledAtUtc,
  int durationMs,
  String appName,
  String category,
  String? sampleTitle,
);

typedef OnPruneRequest = Future<void> Function(DateTime cutoffUtc);

class ContinuousActivityTracker {
  final AppTrackerPort _trackerPort;
  final Duration sampleInterval;
  final Duration maxSampleGap;
  final OnActivitySample onSample;
  final OnPruneRequest? onPrune;

  bool _isRunning = false;
  bool _isTicking = false;
  DateTime? _lastTickAt;
  Timer? _timer;
  Timer? _pruneTimer;

  ContinuousActivityTracker({
    required AppTrackerPort trackerPort,
    required this.onSample,
    this.onPrune,
    this.sampleInterval = const Duration(seconds: 3),
    this.maxSampleGap = const Duration(seconds: 15),
  }) : _trackerPort = trackerPort;

  bool get isRunning => _isRunning;

  void start({DateTime? now}) {
    if (_isRunning) return;
    _isRunning = true;
    _lastTickAt = now ?? DateTime.now().toUtc();
    _startTimer();
    _startPruneTimer();
  }

  void stop() {
    _isRunning = false;
    _lastTickAt = null;
    _timer?.cancel();
    _timer = null;
    _pruneTimer?.cancel();
    _pruneTimer = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(sampleInterval, (_) => tick());
  }

  void _startPruneTimer() {
    _pruneTimer?.cancel();
    _pruneTimer =
        Timer.periodic(const Duration(hours: 1), (_) => pruneOldData());
  }

  Future<void> tick({DateTime? now}) async {
    if (!_isRunning || _isTicking) return;
    _isTicking = true;
    try {
      final current = now ?? DateTime.now().toUtc();
      final last = _lastTickAt;
      _lastTickAt = current;

      if (last == null) return;
      final elapsed = current.difference(last);
      if (elapsed <= Duration.zero || elapsed > maxSampleGap) return;

      final sample = await _trackerPort.sampleActiveWindow();
      if (sample == null || !_isRunning) return;

      final identity =
          AppIdentityRules.identify(sample.rawClass, sample.rawTitle);
      await onSample(
        current,
        elapsed.inMilliseconds,
        identity.appName,
        identity.category,
        identity.sampleTitle,
      );
    } catch (_) {
      // Prevent unhandled async exceptions in background timer zone
    } finally {
      _isTicking = false;
    }
  }

  Future<void> pruneOldData({DateTime? now}) async {
    if (onPrune == null) return;
    final current = now ?? DateTime.now().toUtc();
    final cutoff = current.subtract(const Duration(hours: 24));
    await onPrune!(cutoff);
  }
}
