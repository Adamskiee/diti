import 'package:drift/drift.dart';

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
