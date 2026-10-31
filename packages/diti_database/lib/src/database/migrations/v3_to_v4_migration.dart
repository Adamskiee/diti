import 'package:drift/drift.dart';
import '../diti_database.dart';
import 'schema_migration.dart';

class V3ToV4Migration implements SchemaMigration {
  @override
  int get fromVersion => 3;

  @override
  int get toVersion => 4;

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {
    // 1. Update all cancelled sessions to completed
    await db.customStatement(
      "UPDATE sessions SET outcome = 'completed' WHERE outcome = 'cancelled';",
    );

    // 2. Update all plan blocks linked to a saved session from cancelled to completed
    await db.customStatement(
      "UPDATE plan_blocks SET status = 'completed' WHERE status = 'cancelled' AND session_id IS NOT NULL;",
    );
  }

  Future<void> execute(DitiDatabase db, Migrator m) => migrate(m, db);
}
