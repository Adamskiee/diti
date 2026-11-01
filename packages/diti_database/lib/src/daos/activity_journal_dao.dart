import 'package:drift/drift.dart';
import '../database/diti_database.dart';
import '../database/tables/activity_samples_table.dart';

part 'activity_journal_dao.g.dart';

@DriftAccessor(tables: [ActivitySamples])
class ActivityJournalDao extends DatabaseAccessor<DitiDatabase>
    with _$ActivityJournalDaoMixin {
  ActivityJournalDao(super.db);

  Future<void> insertSample(ActivitySamplesCompanion sample) =>
      into(activitySamples).insert(sample, mode: InsertMode.insertOrReplace);

  Future<List<ActivitySample>> getSamplesBetween(
    DateTime startUtc,
    DateTime endUtc,
  ) {
    return (select(activitySamples)
          ..where((t) =>
              t.sampledAtUtc.isBiggerOrEqualValue(startUtc) &
              t.sampledAtUtc.isSmallerOrEqualValue(endUtc))
          ..orderBy([(t) => OrderingTerm.asc(t.sampledAtUtc)]))
        .get();
  }

  Future<int> pruneOlderThan(DateTime cutoffUtc) {
    return (delete(activitySamples)
          ..where((t) => t.sampledAtUtc.isSmallerThanValue(cutoffUtc)))
        .go();
  }
}
