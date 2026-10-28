class AppUsageSummary {
  final String appName;
  final String category;
  final String? sampleTitle;
  final int durationMs;

  const AppUsageSummary({
    required this.appName,
    required this.category,
    this.sampleTitle,
    required this.durationMs,
  });

  AppUsageSummary copyWith({
    String? appName,
    String? category,
    String? sampleTitle,
    int? durationMs,
  }) {
    return AppUsageSummary(
      appName: appName ?? this.appName,
      category: category ?? this.category,
      sampleTitle: sampleTitle ?? this.sampleTitle,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageSummary &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          category == other.category &&
          sampleTitle == other.sampleTitle &&
          durationMs == other.durationMs;

  @override
  int get hashCode =>
      appName.hashCode ^
      category.hashCode ^
      sampleTitle.hashCode ^
      durationMs.hashCode;
}

class AppIdentityResult {
  final String appName;
  final String category;
  final String? sampleTitle;

  const AppIdentityResult({
    required this.appName,
    required this.category,
    this.sampleTitle,
  });
}
