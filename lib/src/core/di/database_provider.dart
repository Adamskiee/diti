import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the file path for the SQLite database.
///
/// Places the database in [getApplicationDocumentsDirectory].
/// Falls back to 'diti.db' when running in environments where [path_provider]
/// is unavailable (e.g. unit/widget tests).
///
/// If an existing legacy database ('focus_flow.db') is found and 'diti.db'
/// does not yet exist, it automatically migrates by copying the legacy database.
Future<String> resolveDatabasePath() async {
  String targetPath;
  String legacyPath;
  try {
    final dir = await getApplicationDocumentsDirectory();
    targetPath = p.join(dir.path, 'diti.db');
    legacyPath = p.join(dir.path, 'focus_flow.db');
  } catch (_) {
    targetPath = 'diti.db';
    legacyPath = 'focus_flow.db';
  }

  try {
    final targetFile = File(targetPath);
    final legacyFile = File(legacyPath);
    if (!targetFile.existsSync() && legacyFile.existsSync()) {
      legacyFile.copySync(targetPath);
    }
  } catch (_) {
    // Gracefully handle file system errors in restricted test/mock environments.
  }

  return targetPath;
}

/// Creates a [QueryExecutor] that lazily resolves the SQLite database path
/// and opens the database in a background isolate.
QueryExecutor createDefaultDatabaseExecutor({
  Future<String> Function()? pathResolver,
}) {
  return LazyDatabase(() async {
    final resolver = pathResolver ?? resolveDatabasePath;
    final dbFilePath = await resolver();
    return NativeDatabase.createInBackground(File(dbFilePath));
  });
}

/// Constructs a [DitiDatabase] using [createDefaultDatabaseExecutor].
DitiDatabase constructDatabase({
  Future<String> Function()? pathResolver,
}) {
  return DitiDatabase(
    createDefaultDatabaseExecutor(pathResolver: pathResolver),
  );
}

final databaseProvider = Provider<DitiDatabase>((ref) {
  final db = constructDatabase();
  ref.onDispose(() => db.close());
  return db;
});
