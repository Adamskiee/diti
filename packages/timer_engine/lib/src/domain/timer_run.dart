class TimerRun {
  final String runId;

  const TimerRun({required this.runId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerRun &&
          runtimeType == other.runtimeType &&
          runId == other.runId;

  @override
  int get hashCode => runId.hashCode;
}
