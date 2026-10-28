// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_app_usages_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionAppUsagesDaoMixin on DatabaseAccessor<DitiDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $SessionAppUsagesTable get sessionAppUsages =>
      attachedDatabase.sessionAppUsages;
  SessionAppUsagesDaoManager get managers => SessionAppUsagesDaoManager(this);
}

class SessionAppUsagesDaoManager {
  final _$SessionAppUsagesDaoMixin _db;
  SessionAppUsagesDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$SessionAppUsagesTableTableManager get sessionAppUsages =>
      $$SessionAppUsagesTableTableManager(
          _db.attachedDatabase, _db.sessionAppUsages);
}
