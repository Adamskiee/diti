// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_runs_dao.dart';

// ignore_for_file: type=lint
mixin _$TimerRunsDaoMixin on DatabaseAccessor<FocusFlowDatabase> {
  $TimerRunsTable get timerRuns => attachedDatabase.timerRuns;
  $TimerEventsTable get timerEvents => attachedDatabase.timerEvents;
  TimerRunsDaoManager get managers => TimerRunsDaoManager(this);
}

class TimerRunsDaoManager {
  final _$TimerRunsDaoMixin _db;
  TimerRunsDaoManager(this._db);
  $$TimerRunsTableTableManager get timerRuns =>
      $$TimerRunsTableTableManager(_db.attachedDatabase, _db.timerRuns);
  $$TimerEventsTableTableManager get timerEvents =>
      $$TimerEventsTableTableManager(_db.attachedDatabase, _db.timerEvents);
}
