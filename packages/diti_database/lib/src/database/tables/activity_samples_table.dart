import 'package:drift/drift.dart';

@TableIndex(name: 'idx_activity_samples_sampled_at_utc', columns: {#sampledAtUtc})
class ActivitySamples extends Table {
  TextColumn get id => text()();
  DateTimeColumn get sampledAtUtc => dateTime()();
  IntColumn get durationMs => integer()();
  TextColumn get appName => text()();
  TextColumn get category => text()();
  TextColumn get sampleTitle => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
