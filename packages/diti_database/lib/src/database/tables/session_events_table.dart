import 'package:drift/drift.dart';
import 'sessions_table.dart';

class SessionEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get sessionId =>
      text().references(Sessions, #sessionId, onDelete: KeyAction.cascade)();
  TextColumn get eventType => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  TextColumn get phaseId => text().nullable()();
  TextColumn get phaseName => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get outcome => text().nullable()();
  TextColumn get kind =>
      text().withDefault(const Constant('focus'))(); // 'focus' | 'rest'

  @override
  Set<Column> get primaryKey => {eventId};
}
