enum PlanBlockStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

class PlanBlock {
  final String id;
  final String planDate;
  final DateTime scheduledStartUtc;
  final String timezoneId;
  final int plannedDurationMs;
  final String? routineId;
  final int? actualDurationMs;
  final String? sessionId;
  final PlanBlockStatus status;

  PlanBlock({
    required this.id,
    required this.planDate,
    required DateTime scheduledStartUtc,
    required this.timezoneId,
    required this.plannedDurationMs,
    this.routineId,
    this.actualDurationMs,
    this.sessionId,
    this.status = PlanBlockStatus.scheduled,
  }) : scheduledStartUtc = scheduledStartUtc.isUtc
            ? scheduledStartUtc
            : scheduledStartUtc.toUtc();

  PlanBlock copyWith({
    String? id,
    String? planDate,
    DateTime? scheduledStartUtc,
    String? timezoneId,
    int? plannedDurationMs,
    String? routineId,
    int? actualDurationMs,
    String? sessionId,
    PlanBlockStatus? status,
  }) {
    return PlanBlock(
      id: id ?? this.id,
      planDate: planDate ?? this.planDate,
      scheduledStartUtc: scheduledStartUtc ?? this.scheduledStartUtc,
      timezoneId: timezoneId ?? this.timezoneId,
      plannedDurationMs: plannedDurationMs ?? this.plannedDurationMs,
      routineId: routineId ?? this.routineId,
      actualDurationMs: actualDurationMs ?? this.actualDurationMs,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
    );
  }
}
