import 'package:drift/drift.dart';

class TimerRuns extends Table {
  TextColumn get runId => text()();
  TextColumn get status => text()();
  TextColumn get phaseStatus => text()();
  IntColumn get currentPhaseIndex => integer()();
  IntColumn get repeatIndex => integer()();
  IntColumn get accumulatedMs => integer()();
  DateTimeColumn get phaseStartedAtUtc => dateTime()();
  DateTimeColumn get pausedAtUtc => dateTime().nullable()();
  IntColumn get stateVersion => integer()();
  TextColumn get lastEventId => text().nullable()();
  TextColumn get routineSnapshotJson => text()();

  @override
  Set<Column> get primaryKey => {runId};
}
