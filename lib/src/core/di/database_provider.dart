import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the file path for the SQLite database.
///
/// On mobile platforms (Android/iOS), places the database in [getApplicationDocumentsDirectory].
/// Falls back to 'focus_flow.db' on desktop or when running in environments where [path_provider]
/// is unavailable (e.g. unit/widget tests).
Future<String> resolveDatabasePath() async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, 'focus_flow.db');
    } catch (_) {
      return 'focus_flow.db';
    }
  }
  return 'focus_flow.db';
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

/// Constructs a [FocusFlowDatabase] using [createDefaultDatabaseExecutor].
FocusFlowDatabase constructDatabase({
  Future<String> Function()? pathResolver,
}) {
  return FocusFlowDatabase(
    createDefaultDatabaseExecutor(pathResolver: pathResolver),
  );
}

final databaseProvider = Provider<FocusFlowDatabase>((ref) {
  final db = constructDatabase();
  ref.onDispose(() => db.close());
  return db;
});
