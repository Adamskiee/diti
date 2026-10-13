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
  }) : scheduledStartUtc =
            scheduledStartUtc.isUtc ? scheduledStartUtc : scheduledStartUtc.toUtc();
}
