abstract interface class NotificationPort {
  Future<void> scheduleBoundaryNotification({
    required String runId,
    required String phaseId,
    required String phaseName,
    required DateTime expectedUtc,
  });

  Future<void> cancelBoundaries(String runId);
}
