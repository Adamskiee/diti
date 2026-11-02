import '../domain/activity_sample_record.dart';
import '../domain/activity_usage_summary_record.dart';

abstract class ActivityJournalRepository {
  Future<void> recordSample(ActivitySampleRecord sample);

  Future<List<ActivityUsageSummaryRecord>> aggregateUsageBetween(
    DateTime startUtc,
    DateTime endUtc,
  );

  Future<int> pruneOlderThan(DateTime cutoffUtc);
}
