import 'package:drift/drift.dart';

class PlanBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get planDate => text()(); // 'YYYY-MM-DD'
  DateTimeColumn get scheduledStartUtc => dateTime()();
  TextColumn get timezoneId => text()();
  IntColumn get plannedDurationMs => integer()();
  TextColumn get routineId => text().nullable()();
  IntColumn get actualDurationMs => integer().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get status =>
      text()(); // 'scheduled' | 'inProgress' | 'completed' | 'cancelled'

  @override
  Set<Column> get primaryKey => {id};
}
