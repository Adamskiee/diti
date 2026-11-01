import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../domain/activity_sample_record.dart';
import '../domain/activity_usage_summary_record.dart';
import 'activity_journal_repository.dart';

class DriftActivityJournalRepository implements ActivityJournalRepository {
  final DitiDatabase _db;

  DriftActivityJournalRepository(this._db);

  @override
  Future<void> recordSample(ActivitySampleRecord sample) async {
    await _db.activityJournalDao.insertSample(
      ActivitySamplesCompanion(
        id: Value(sample.id),
        sampledAtUtc: Value(sample.sampledAtUtc),
        durationMs: Value(sample.durationMs),
        appName: Value(sample.appName),
        category: Value(sample.category),
        sampleTitle: Value(sample.sampleTitle),
      ),
    );
  }

  @override
  Future<List<ActivityUsageSummaryRecord>> aggregateUsageBetween(
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final rows = await _db.activityJournalDao.getSamplesBetween(startUtc, endUtc);
    final Map<String, ActivityUsageSummaryRecord> aggregated = {};

    for (final row in rows) {
      final key = '${row.appName}::${row.category}';
      final existing = aggregated[key];
      if (existing == null) {
        aggregated[key] = ActivityUsageSummaryRecord(
          appName: row.appName,
          category: row.category,
          sampleTitle: row.sampleTitle,
          durationMs: row.durationMs,
        );
      } else {
        aggregated[key] = ActivityUsageSummaryRecord(
          appName: row.appName,
          category: row.category,
          sampleTitle: existing.sampleTitle ?? row.sampleTitle,
          durationMs: existing.durationMs + row.durationMs,
        );
      }
    }

    final result = aggregated.values.toList();
    result.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    return result;
  }

  @override
  Future<int> pruneOlderThan(DateTime cutoffUtc) =>
      _db.activityJournalDao.pruneOlderThan(cutoffUtc);
}
