import 'package:drift/drift.dart';

class Sessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get routineId => text().nullable()();
  TextColumn get planBlockId => text().nullable()();
  TextColumn get routineName => text()();
  DateTimeColumn get startedAtUtc => dateTime()();
  DateTimeColumn get endedAtUtc => dateTime()();
  IntColumn get totalDurationMs => integer()();
  TextColumn get outcome => text()(); // 'completed' | 'cancelled' | 'interrupted'
  TextColumn get routineSnapshotJson => text()();

  @override
  Set<Column> get primaryKey => {sessionId};
}
