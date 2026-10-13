import 'package:timer_engine/src/ports/notification_port.dart';

class ScheduledBoundary {
  final String runId;
  final String phaseId;
  final String phaseName;
  final DateTime expectedUtc;

  ScheduledBoundary({
    required this.runId,
    required this.phaseId,
    required this.phaseName,
    required this.expectedUtc,
  });
}

class InMemoryNotificationPort implements NotificationPort {
  final List<ScheduledBoundary> scheduledBoundaries = [];

  @override
  Future<void> scheduleBoundaryNotification({
    required String runId,
    required String phaseId,
    required String phaseName,
    required DateTime expectedUtc,
  }) async {
    scheduledBoundaries.add(ScheduledBoundary(
      runId: runId,
      phaseId: phaseId,
      phaseName: phaseName,
      expectedUtc: expectedUtc,
    ));
  }

  @override
  Future<void> cancelBoundaries(String runId) async {
    scheduledBoundaries.removeWhere((b) => b.runId == runId);
  }
}
