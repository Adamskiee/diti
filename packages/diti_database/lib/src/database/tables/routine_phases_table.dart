import 'package:drift/drift.dart';
import 'routines_table.dart';

class RoutinePhases extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();
  TextColumn get name => text()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get transitionPolicy => text()(); // 'auto' | 'manual'

  @override
  Set<Column> get primaryKey => {routineId, id};
}
