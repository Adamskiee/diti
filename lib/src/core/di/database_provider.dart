import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_flow_database/focus_flow_database.dart';

final databaseProvider = Provider<FocusFlowDatabase>((ref) {
  final db = FocusFlowDatabase.defaults();
  ref.onDispose(() => db.close());
  return db;
});
