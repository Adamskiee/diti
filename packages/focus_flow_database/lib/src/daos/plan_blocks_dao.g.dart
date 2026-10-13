// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_blocks_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanBlocksDaoMixin on DatabaseAccessor<FocusFlowDatabase> {
  $PlanBlocksTable get planBlocks => attachedDatabase.planBlocks;
  PlanBlocksDaoManager get managers => PlanBlocksDaoManager(this);
}

class PlanBlocksDaoManager {
  final _$PlanBlocksDaoMixin _db;
  PlanBlocksDaoManager(this._db);
  $$PlanBlocksTableTableManager get planBlocks =>
      $$PlanBlocksTableTableManager(_db.attachedDatabase, _db.planBlocks);
}
