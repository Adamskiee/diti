class ActivitySampleRecord {
  final String id;
  final DateTime sampledAtUtc;
  final int durationMs;
  final String appName;
  final String category;
  final String? sampleTitle;

  const ActivitySampleRecord({
    required this.id,
    required this.sampledAtUtc,
    required this.durationMs,
    required this.appName,
    required this.category,
    this.sampleTitle,
  });
}
