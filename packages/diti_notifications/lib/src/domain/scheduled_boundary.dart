class ScheduledBoundary {
  final int notificationId;
  final String runId;
  final int phaseIndex;
  final String phaseId;
  final String phaseName;
  final String title;
  final String body;
  final DateTime scheduledUtc;
  final bool requiresAction;
  final bool isTerminal;

  const ScheduledBoundary({
    required this.notificationId,
    required this.runId,
    required this.phaseIndex,
    required this.phaseId,
    required this.phaseName,
    required this.title,
    required this.body,
    required this.scheduledUtc,
    required this.requiresAction,
    required this.isTerminal,
  });

  @override
  String toString() =>
      'ScheduledBoundary($notificationId, $phaseName, $scheduledUtc, requiresAction: $requiresAction)';
}
