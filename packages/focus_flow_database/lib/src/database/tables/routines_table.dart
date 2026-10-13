import 'package:drift/drift.dart';

class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get repeatMode => text()(); // 'count' | 'forever'
  IntColumn get repeatCount => integer().nullable()();
  DateTimeColumn get createdAtUtc => dateTime()();
  DateTimeColumn get updatedAtUtc => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
