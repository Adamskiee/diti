import 'package:timer_engine/timer_engine.dart';
import 'session_app_usage_record.dart';

enum SessionOutcome {
  completed,
  cancelled,
  interrupted,
}

class SessionEventRecord {
  final String eventId;
  final String sessionId;
  final String eventType;
  final DateTime occurredAtUtc;
  final String? phaseId;
  final String? phaseName;
  final int durationMs;
  final String? outcome;

  /// Whether the phase this event belongs to is a focus phase or a rest
  /// phase. Events that were recorded before the kinds existed are focus.
  final PhaseKind kind;

  SessionEventRecord({
    required this.eventId,
    required this.sessionId,
    required this.eventType,
    required DateTime occurredAtUtc,
    this.phaseId,
    this.phaseName,
    this.durationMs = 0,
    this.outcome,
    this.kind = PhaseKind.focus,
  }) : occurredAtUtc =
            occurredAtUtc.isUtc ? occurredAtUtc : occurredAtUtc.toUtc();
}

class SessionRecord {
  final String sessionId;
  final String? routineId;
  final String? planBlockId;
  final String routineName;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final int totalDurationMs;
  final SessionOutcome outcome;
  final Routine routineSnapshot;
  final List<SessionEventRecord> events;
  final List<SessionAppUsageRecord> appUsages;

  SessionRecord({
    required this.sessionId,
    this.routineId,
    this.planBlockId,
    required this.routineName,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    required this.totalDurationMs,
    required this.outcome,
    required this.routineSnapshot,
    this.events = const [],
    this.appUsages = const [],
  })  : startedAtUtc = startedAtUtc.isUtc ? startedAtUtc : startedAtUtc.toUtc(),
        endedAtUtc = endedAtUtc.isUtc ? endedAtUtc : endedAtUtc.toUtc();
}
