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

  const TimerEvent({
    required this.eventId,
    required this.runId,
    required this.type,
    required this.occurredAtUtc,
    this.durationMs = 0,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          runId == other.runId &&
          type == other.type &&
          occurredAtUtc == other.occurredAtUtc &&
          durationMs == other.durationMs;

  @override
  int get hashCode =>
      Object.hash(eventId, runId, type, occurredAtUtc, durationMs);
}
