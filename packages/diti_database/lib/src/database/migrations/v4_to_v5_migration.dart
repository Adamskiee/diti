import 'package:drift/drift.dart';
import '../diti_database.dart';
import 'schema_migration.dart';

class V4ToV5Migration implements SchemaMigration {
  @override
  int get fromVersion => 4;

  @override
  int get toVersion => 5;

  @override
  Future<void> migrate(Migrator m, DitiDatabase db) async {
    await m.createTable(db.activitySamples);
    await m.createIndex(Index('idx_activity_samples_sampled_at_utc',
        'CREATE INDEX IF NOT EXISTS idx_activity_samples_sampled_at_utc ON activity_samples (sampled_at_utc);'));
  }

  Future<void> execute(DitiDatabase db, Migrator m) => migrate(m, db);
}
