// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_journal_dao.dart';

// ignore_for_file: type=lint
mixin _$ActivityJournalDaoMixin on DatabaseAccessor<DitiDatabase> {
  $ActivitySamplesTable get activitySamples => attachedDatabase.activitySamples;
  ActivityJournalDaoManager get managers => ActivityJournalDaoManager(this);
}

class ActivityJournalDaoManager {
  final _$ActivityJournalDaoMixin _db;
  ActivityJournalDaoManager(this._db);
  $$ActivitySamplesTableTableManager get activitySamples =>
      $$ActivitySamplesTableTableManager(
          _db.attachedDatabase, _db.activitySamples);
}
