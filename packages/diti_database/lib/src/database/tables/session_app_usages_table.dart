import 'package:drift/drift.dart';
import 'sessions_table.dart';

class SessionAppUsages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(
        Sessions,
        #sessionId,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get appName => text()();
  TextColumn get category => text()();
  TextColumn get sampleTitle => text().nullable()();
  IntColumn get durationMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
