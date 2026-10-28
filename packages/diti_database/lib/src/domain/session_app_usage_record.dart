class SessionAppUsageRecord {
  final String id;
  final String sessionId;
  final String appName;
  final String category;
  final String? sampleTitle;
  final int durationMs;

  const SessionAppUsageRecord({
    required this.id,
    required this.sessionId,
    required this.appName,
    required this.category,
    this.sampleTitle,
    required this.durationMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAppUsageRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          appName == other.appName &&
          category == other.category &&
          sampleTitle == other.sampleTitle &&
          durationMs == other.durationMs;

  @override
  int get hashCode =>
      id.hashCode ^
      sessionId.hashCode ^
      appName.hashCode ^
      category.hashCode ^
      sampleTitle.hashCode ^
      durationMs.hashCode;
}
