import 'package:drift/drift.dart';
import 'timer_runs_table.dart';

class TimerEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get runId =>
      text().references(TimerRuns, #runId, onDelete: KeyAction.cascade)();
  TextColumn get eventType => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {eventId};
}
