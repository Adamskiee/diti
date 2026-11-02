import 'package:drift/drift.dart';
import '../diti_database.dart';
import 'schema_migration.dart';

class V2ToV3Migration implements SchemaMigration {
  @override
  int get fromVersion => 2;

  @override
  int get toVersion => 3;

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='session_app_usages'",
        )
        .get();
    if (tables.isEmpty) {
      await m.createTable(db.sessionAppUsages);
    }
  }

  Future<void> execute(DitiDatabase db, Migrator m) => migrate(m, db);
}
