class ActivityUsageSummaryRecord {
  final String appName;
  final String category;
  final String? sampleTitle;
  final int durationMs;

  const ActivityUsageSummaryRecord({
    required this.appName,
    required this.category,
    this.sampleTitle,
    required this.durationMs,
  });
}
