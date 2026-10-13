enum TimerEventType {
  runStarted,
  runPaused,
  runResumed,
  phaseFinished,
  phaseSkipped,
  runCompleted,
  runCancelled,
  reconciled,
}

class TimerEvent {
  final String eventId;
  final String runId;
  final TimerEventType type;
  final DateTime occurredAtUtc;
  final int durationMs;
  final Map<String, dynamic> metadata;

  TimerEvent({
    required this.eventId,
    required this.runId,
    required this.type,
    required DateTime occurredAtUtc,
    this.durationMs = 0,
    this.metadata = const {},
  }) : occurredAtUtc =
            occurredAtUtc.isUtc ? occurredAtUtc : occurredAtUtc.toUtc();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          runId == other.runId &&
          type == other.type &&
          occurredAtUtc == other.occurredAtUtc &&
          durationMs == other.durationMs &&
          _deepEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        eventId,
        runId,
        type,
        occurredAtUtc,
        durationMs,
        _mapHashCode(metadata),
      );

  static bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  static int _mapHashCode(Map<String, dynamic> map) {
    var result = 0;
    for (final entry in map.entries) {
      result ^= Object.hash(entry.key, entry.value);
    }
    return result;
  }
}
