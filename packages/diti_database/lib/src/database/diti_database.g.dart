// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diti_database.dart';

// ignore_for_file: type=lint
class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repeatModeMeta =
      const VerificationMeta('repeatMode');
  @override
  late final GeneratedColumn<String> repeatMode = GeneratedColumn<String>(
      'repeat_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repeatCountMeta =
      const VerificationMeta('repeatCount');
  @override
  late final GeneratedColumn<int> repeatCount = GeneratedColumn<int>(
      'repeat_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtUtcMeta =
      const VerificationMeta('createdAtUtc');
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
      'created_at_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtUtcMeta =
      const VerificationMeta('updatedAtUtc');
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
      'updated_at_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, repeatMode, repeatCount, createdAtUtc, updatedAtUtc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<Routine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('repeat_mode')) {
      context.handle(
          _repeatModeMeta,
          repeatMode.isAcceptableOrUnknown(
              data['repeat_mode']!, _repeatModeMeta));
    } else if (isInserting) {
      context.missing(_repeatModeMeta);
    }
    if (data.containsKey('repeat_count')) {
      context.handle(
          _repeatCountMeta,
          repeatCount.isAcceptableOrUnknown(
              data['repeat_count']!, _repeatCountMeta));
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
          _createdAtUtcMeta,
          createdAtUtc.isAcceptableOrUnknown(
              data['created_at_utc']!, _createdAtUtcMeta));
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
          _updatedAtUtcMeta,
          updatedAtUtc.isAcceptableOrUnknown(
              data['updated_at_utc']!, _updatedAtUtcMeta));
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      repeatMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat_mode'])!,
      repeatCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repeat_count']),
      createdAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}created_at_utc'])!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}updated_at_utc'])!,
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class Routine extends DataClass implements Insertable<Routine> {
  final String id;
  final String name;
  final String repeatMode;
  final int? repeatCount;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const Routine(
      {required this.id,
      required this.name,
      required this.repeatMode,
      this.repeatCount,
      required this.createdAtUtc,
      required this.updatedAtUtc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['repeat_mode'] = Variable<String>(repeatMode);
    if (!nullToAbsent || repeatCount != null) {
      map['repeat_count'] = Variable<int>(repeatCount);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      name: Value(name),
      repeatMode: Value(repeatMode),
      repeatCount: repeatCount == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatCount),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      repeatMode: serializer.fromJson<String>(json['repeatMode']),
      repeatCount: serializer.fromJson<int?>(json['repeatCount']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'repeatMode': serializer.toJson<String>(repeatMode),
      'repeatCount': serializer.toJson<int?>(repeatCount),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  Routine copyWith(
          {String? id,
          String? name,
          String? repeatMode,
          Value<int?> repeatCount = const Value.absent(),
          DateTime? createdAtUtc,
          DateTime? updatedAtUtc}) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        repeatMode: repeatMode ?? this.repeatMode,
        repeatCount: repeatCount.present ? repeatCount.value : this.repeatCount,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
        updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      repeatMode:
          data.repeatMode.present ? data.repeatMode.value : this.repeatMode,
      repeatCount:
          data.repeatCount.present ? data.repeatCount.value : this.repeatCount,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('repeatCount: $repeatCount, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, repeatMode, repeatCount, createdAtUtc, updatedAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.id == this.id &&
          other.name == this.name &&
          other.repeatMode == this.repeatMode &&
          other.repeatCount == this.repeatCount &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> repeatMode;
  final Value<int?> repeatCount;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.repeatCount = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinesCompanion.insert({
    required String id,
    required String name,
    required String repeatMode,
    this.repeatCount = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        repeatMode = Value(repeatMode),
        createdAtUtc = Value(createdAtUtc),
        updatedAtUtc = Value(updatedAtUtc);
  static Insertable<Routine> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? repeatMode,
    Expression<int>? repeatCount,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (repeatCount != null) 'repeat_count': repeatCount,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? repeatMode,
      Value<int?>? repeatCount,
      Value<DateTime>? createdAtUtc,
      Value<DateTime>? updatedAtUtc,
      Value<int>? rowid}) {
    return RoutinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatCount: repeatCount ?? this.repeatCount,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<String>(repeatMode.value);
    }
    if (repeatCount.present) {
      map['repeat_count'] = Variable<int>(repeatCount.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('repeatCount: $repeatCount, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutinePhasesTable extends RoutinePhases
    with TableInfo<$RoutinePhasesTable, RoutinePhase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinePhasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES routines (id) ON DELETE CASCADE'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _transitionPolicyMeta =
      const VerificationMeta('transitionPolicy');
  @override
  late final GeneratedColumn<String> transitionPolicy = GeneratedColumn<String>(
      'transition_policy', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, routineId, orderIndex, name, durationMs, transitionPolicy];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_phases';
  @override
  VerificationContext validateIntegrity(Insertable<RoutinePhase> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('transition_policy')) {
      context.handle(
          _transitionPolicyMeta,
          transitionPolicy.isAcceptableOrUnknown(
              data['transition_policy']!, _transitionPolicyMeta));
    } else if (isInserting) {
      context.missing(_transitionPolicyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routineId, id};
  @override
  RoutinePhase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutinePhase(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      transitionPolicy: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transition_policy'])!,
    );
  }

  @override
  $RoutinePhasesTable createAlias(String alias) {
    return $RoutinePhasesTable(attachedDatabase, alias);
  }
}

class RoutinePhase extends DataClass implements Insertable<RoutinePhase> {
  final String id;
  final String routineId;
  final int orderIndex;
  final String name;
  final int? durationMs;
  final String transitionPolicy;
  const RoutinePhase(
      {required this.id,
      required this.routineId,
      required this.orderIndex,
      required this.name,
      this.durationMs,
      required this.transitionPolicy});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['routine_id'] = Variable<String>(routineId);
    map['order_index'] = Variable<int>(orderIndex);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['transition_policy'] = Variable<String>(transitionPolicy);
    return map;
  }

  RoutinePhasesCompanion toCompanion(bool nullToAbsent) {
    return RoutinePhasesCompanion(
      id: Value(id),
      routineId: Value(routineId),
      orderIndex: Value(orderIndex),
      name: Value(name),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      transitionPolicy: Value(transitionPolicy),
    );
  }

  factory RoutinePhase.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutinePhase(
      id: serializer.fromJson<String>(json['id']),
      routineId: serializer.fromJson<String>(json['routineId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      name: serializer.fromJson<String>(json['name']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      transitionPolicy: serializer.fromJson<String>(json['transitionPolicy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routineId': serializer.toJson<String>(routineId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'name': serializer.toJson<String>(name),
      'durationMs': serializer.toJson<int?>(durationMs),
      'transitionPolicy': serializer.toJson<String>(transitionPolicy),
    };
  }

  RoutinePhase copyWith(
          {String? id,
          String? routineId,
          int? orderIndex,
          String? name,
          Value<int?> durationMs = const Value.absent(),
          String? transitionPolicy}) =>
      RoutinePhase(
        id: id ?? this.id,
        routineId: routineId ?? this.routineId,
        orderIndex: orderIndex ?? this.orderIndex,
        name: name ?? this.name,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        transitionPolicy: transitionPolicy ?? this.transitionPolicy,
      );
  RoutinePhase copyWithCompanion(RoutinePhasesCompanion data) {
    return RoutinePhase(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      name: data.name.present ? data.name.value : this.name,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      transitionPolicy: data.transitionPolicy.present
          ? data.transitionPolicy.value
          : this.transitionPolicy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutinePhase(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('name: $name, ')
          ..write('durationMs: $durationMs, ')
          ..write('transitionPolicy: $transitionPolicy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, routineId, orderIndex, name, durationMs, transitionPolicy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutinePhase &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.orderIndex == this.orderIndex &&
          other.name == this.name &&
          other.durationMs == this.durationMs &&
          other.transitionPolicy == this.transitionPolicy);
}

class RoutinePhasesCompanion extends UpdateCompanion<RoutinePhase> {
  final Value<String> id;
  final Value<String> routineId;
  final Value<int> orderIndex;
  final Value<String> name;
  final Value<int?> durationMs;
  final Value<String> transitionPolicy;
  final Value<int> rowid;
  const RoutinePhasesCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.name = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.transitionPolicy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinePhasesCompanion.insert({
    required String id,
    required String routineId,
    required int orderIndex,
    required String name,
    this.durationMs = const Value.absent(),
    required String transitionPolicy,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        routineId = Value(routineId),
        orderIndex = Value(orderIndex),
        name = Value(name),
        transitionPolicy = Value(transitionPolicy);
  static Insertable<RoutinePhase> custom({
    Expression<String>? id,
    Expression<String>? routineId,
    Expression<int>? orderIndex,
    Expression<String>? name,
    Expression<int>? durationMs,
    Expression<String>? transitionPolicy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (name != null) 'name': name,
      if (durationMs != null) 'duration_ms': durationMs,
      if (transitionPolicy != null) 'transition_policy': transitionPolicy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinePhasesCompanion copyWith(
      {Value<String>? id,
      Value<String>? routineId,
      Value<int>? orderIndex,
      Value<String>? name,
      Value<int?>? durationMs,
      Value<String>? transitionPolicy,
      Value<int>? rowid}) {
    return RoutinePhasesCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      orderIndex: orderIndex ?? this.orderIndex,
      name: name ?? this.name,
      durationMs: durationMs ?? this.durationMs,
      transitionPolicy: transitionPolicy ?? this.transitionPolicy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (transitionPolicy.present) {
      map['transition_policy'] = Variable<String>(transitionPolicy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinePhasesCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('name: $name, ')
          ..write('durationMs: $durationMs, ')
          ..write('transitionPolicy: $transitionPolicy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerRunsTable extends TimerRuns
    with TableInfo<$TimerRunsTable, TimerRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
      'run_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phaseStatusMeta =
      const VerificationMeta('phaseStatus');
  @override
  late final GeneratedColumn<String> phaseStatus = GeneratedColumn<String>(
      'phase_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentPhaseIndexMeta =
      const VerificationMeta('currentPhaseIndex');
  @override
  late final GeneratedColumn<int> currentPhaseIndex = GeneratedColumn<int>(
      'current_phase_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repeatIndexMeta =
      const VerificationMeta('repeatIndex');
  @override
  late final GeneratedColumn<int> repeatIndex = GeneratedColumn<int>(
      'repeat_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _accumulatedMsMeta =
      const VerificationMeta('accumulatedMs');
  @override
  late final GeneratedColumn<int> accumulatedMs = GeneratedColumn<int>(
      'accumulated_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _phaseStartedAtUtcMeta =
      const VerificationMeta('phaseStartedAtUtc');
  @override
  late final GeneratedColumn<DateTime> phaseStartedAtUtc =
      GeneratedColumn<DateTime>('phase_started_at_utc', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _pausedAtUtcMeta =
      const VerificationMeta('pausedAtUtc');
  @override
  late final GeneratedColumn<DateTime> pausedAtUtc = GeneratedColumn<DateTime>(
      'paused_at_utc', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _stateVersionMeta =
      const VerificationMeta('stateVersion');
  @override
  late final GeneratedColumn<int> stateVersion = GeneratedColumn<int>(
      'state_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastEventIdMeta =
      const VerificationMeta('lastEventId');
  @override
  late final GeneratedColumn<String> lastEventId = GeneratedColumn<String>(
      'last_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routineSnapshotJsonMeta =
      const VerificationMeta('routineSnapshotJson');
  @override
  late final GeneratedColumn<String> routineSnapshotJson =
      GeneratedColumn<String>('routine_snapshot_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        runId,
        status,
        phaseStatus,
        currentPhaseIndex,
        repeatIndex,
        accumulatedMs,
        phaseStartedAtUtc,
        pausedAtUtc,
        stateVersion,
        lastEventId,
        routineSnapshotJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_runs';
  @override
  VerificationContext validateIntegrity(Insertable<TimerRun> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
          _runIdMeta, runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta));
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('phase_status')) {
      context.handle(
          _phaseStatusMeta,
          phaseStatus.isAcceptableOrUnknown(
              data['phase_status']!, _phaseStatusMeta));
    } else if (isInserting) {
      context.missing(_phaseStatusMeta);
    }
    if (data.containsKey('current_phase_index')) {
      context.handle(
          _currentPhaseIndexMeta,
          currentPhaseIndex.isAcceptableOrUnknown(
              data['current_phase_index']!, _currentPhaseIndexMeta));
    } else if (isInserting) {
      context.missing(_currentPhaseIndexMeta);
    }
    if (data.containsKey('repeat_index')) {
      context.handle(
          _repeatIndexMeta,
          repeatIndex.isAcceptableOrUnknown(
              data['repeat_index']!, _repeatIndexMeta));
    } else if (isInserting) {
      context.missing(_repeatIndexMeta);
    }
    if (data.containsKey('accumulated_ms')) {
      context.handle(
          _accumulatedMsMeta,
          accumulatedMs.isAcceptableOrUnknown(
              data['accumulated_ms']!, _accumulatedMsMeta));
    } else if (isInserting) {
      context.missing(_accumulatedMsMeta);
    }
    if (data.containsKey('phase_started_at_utc')) {
      context.handle(
          _phaseStartedAtUtcMeta,
          phaseStartedAtUtc.isAcceptableOrUnknown(
              data['phase_started_at_utc']!, _phaseStartedAtUtcMeta));
    } else if (isInserting) {
      context.missing(_phaseStartedAtUtcMeta);
    }
    if (data.containsKey('paused_at_utc')) {
      context.handle(
          _pausedAtUtcMeta,
          pausedAtUtc.isAcceptableOrUnknown(
              data['paused_at_utc']!, _pausedAtUtcMeta));
    }
    if (data.containsKey('state_version')) {
      context.handle(
          _stateVersionMeta,
          stateVersion.isAcceptableOrUnknown(
              data['state_version']!, _stateVersionMeta));
    } else if (isInserting) {
      context.missing(_stateVersionMeta);
    }
    if (data.containsKey('last_event_id')) {
      context.handle(
          _lastEventIdMeta,
          lastEventId.isAcceptableOrUnknown(
              data['last_event_id']!, _lastEventIdMeta));
    }
    if (data.containsKey('routine_snapshot_json')) {
      context.handle(
          _routineSnapshotJsonMeta,
          routineSnapshotJson.isAcceptableOrUnknown(
              data['routine_snapshot_json']!, _routineSnapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_routineSnapshotJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId};
  @override
  TimerRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerRun(
      runId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      phaseStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phase_status'])!,
      currentPhaseIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_phase_index'])!,
      repeatIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repeat_index'])!,
      accumulatedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accumulated_ms'])!,
      phaseStartedAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}phase_started_at_utc'])!,
      pausedAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paused_at_utc']),
      stateVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state_version'])!,
      lastEventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_event_id']),
      routineSnapshotJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}routine_snapshot_json'])!,
    );
  }

  @override
  $TimerRunsTable createAlias(String alias) {
    return $TimerRunsTable(attachedDatabase, alias);
  }
}

class TimerRun extends DataClass implements Insertable<TimerRun> {
  final String runId;
  final String status;
  final String phaseStatus;
  final int currentPhaseIndex;
  final int repeatIndex;
  final int accumulatedMs;
  final DateTime phaseStartedAtUtc;
  final DateTime? pausedAtUtc;
  final int stateVersion;
  final String? lastEventId;
  final String routineSnapshotJson;
  const TimerRun(
      {required this.runId,
      required this.status,
      required this.phaseStatus,
      required this.currentPhaseIndex,
      required this.repeatIndex,
      required this.accumulatedMs,
      required this.phaseStartedAtUtc,
      this.pausedAtUtc,
      required this.stateVersion,
      this.lastEventId,
      required this.routineSnapshotJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['status'] = Variable<String>(status);
    map['phase_status'] = Variable<String>(phaseStatus);
    map['current_phase_index'] = Variable<int>(currentPhaseIndex);
    map['repeat_index'] = Variable<int>(repeatIndex);
    map['accumulated_ms'] = Variable<int>(accumulatedMs);
    map['phase_started_at_utc'] = Variable<DateTime>(phaseStartedAtUtc);
    if (!nullToAbsent || pausedAtUtc != null) {
      map['paused_at_utc'] = Variable<DateTime>(pausedAtUtc);
    }
    map['state_version'] = Variable<int>(stateVersion);
    if (!nullToAbsent || lastEventId != null) {
      map['last_event_id'] = Variable<String>(lastEventId);
    }
    map['routine_snapshot_json'] = Variable<String>(routineSnapshotJson);
    return map;
  }

  TimerRunsCompanion toCompanion(bool nullToAbsent) {
    return TimerRunsCompanion(
      runId: Value(runId),
      status: Value(status),
      phaseStatus: Value(phaseStatus),
      currentPhaseIndex: Value(currentPhaseIndex),
      repeatIndex: Value(repeatIndex),
      accumulatedMs: Value(accumulatedMs),
      phaseStartedAtUtc: Value(phaseStartedAtUtc),
      pausedAtUtc: pausedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAtUtc),
      stateVersion: Value(stateVersion),
      lastEventId: lastEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEventId),
      routineSnapshotJson: Value(routineSnapshotJson),
    );
  }

  factory TimerRun.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerRun(
      runId: serializer.fromJson<String>(json['runId']),
      status: serializer.fromJson<String>(json['status']),
      phaseStatus: serializer.fromJson<String>(json['phaseStatus']),
      currentPhaseIndex: serializer.fromJson<int>(json['currentPhaseIndex']),
      repeatIndex: serializer.fromJson<int>(json['repeatIndex']),
      accumulatedMs: serializer.fromJson<int>(json['accumulatedMs']),
      phaseStartedAtUtc:
          serializer.fromJson<DateTime>(json['phaseStartedAtUtc']),
      pausedAtUtc: serializer.fromJson<DateTime?>(json['pausedAtUtc']),
      stateVersion: serializer.fromJson<int>(json['stateVersion']),
      lastEventId: serializer.fromJson<String?>(json['lastEventId']),
      routineSnapshotJson:
          serializer.fromJson<String>(json['routineSnapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'status': serializer.toJson<String>(status),
      'phaseStatus': serializer.toJson<String>(phaseStatus),
      'currentPhaseIndex': serializer.toJson<int>(currentPhaseIndex),
      'repeatIndex': serializer.toJson<int>(repeatIndex),
      'accumulatedMs': serializer.toJson<int>(accumulatedMs),
      'phaseStartedAtUtc': serializer.toJson<DateTime>(phaseStartedAtUtc),
      'pausedAtUtc': serializer.toJson<DateTime?>(pausedAtUtc),
      'stateVersion': serializer.toJson<int>(stateVersion),
      'lastEventId': serializer.toJson<String?>(lastEventId),
      'routineSnapshotJson': serializer.toJson<String>(routineSnapshotJson),
    };
  }

  TimerRun copyWith(
          {String? runId,
          String? status,
          String? phaseStatus,
          int? currentPhaseIndex,
          int? repeatIndex,
          int? accumulatedMs,
          DateTime? phaseStartedAtUtc,
          Value<DateTime?> pausedAtUtc = const Value.absent(),
          int? stateVersion,
          Value<String?> lastEventId = const Value.absent(),
          String? routineSnapshotJson}) =>
      TimerRun(
        runId: runId ?? this.runId,
        status: status ?? this.status,
        phaseStatus: phaseStatus ?? this.phaseStatus,
        currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
        repeatIndex: repeatIndex ?? this.repeatIndex,
        accumulatedMs: accumulatedMs ?? this.accumulatedMs,
        phaseStartedAtUtc: phaseStartedAtUtc ?? this.phaseStartedAtUtc,
        pausedAtUtc: pausedAtUtc.present ? pausedAtUtc.value : this.pausedAtUtc,
        stateVersion: stateVersion ?? this.stateVersion,
        lastEventId: lastEventId.present ? lastEventId.value : this.lastEventId,
        routineSnapshotJson: routineSnapshotJson ?? this.routineSnapshotJson,
      );
  TimerRun copyWithCompanion(TimerRunsCompanion data) {
    return TimerRun(
      runId: data.runId.present ? data.runId.value : this.runId,
      status: data.status.present ? data.status.value : this.status,
      phaseStatus:
          data.phaseStatus.present ? data.phaseStatus.value : this.phaseStatus,
      currentPhaseIndex: data.currentPhaseIndex.present
          ? data.currentPhaseIndex.value
          : this.currentPhaseIndex,
      repeatIndex:
          data.repeatIndex.present ? data.repeatIndex.value : this.repeatIndex,
      accumulatedMs: data.accumulatedMs.present
          ? data.accumulatedMs.value
          : this.accumulatedMs,
      phaseStartedAtUtc: data.phaseStartedAtUtc.present
          ? data.phaseStartedAtUtc.value
          : this.phaseStartedAtUtc,
      pausedAtUtc:
          data.pausedAtUtc.present ? data.pausedAtUtc.value : this.pausedAtUtc,
      stateVersion: data.stateVersion.present
          ? data.stateVersion.value
          : this.stateVersion,
      lastEventId:
          data.lastEventId.present ? data.lastEventId.value : this.lastEventId,
      routineSnapshotJson: data.routineSnapshotJson.present
          ? data.routineSnapshotJson.value
          : this.routineSnapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerRun(')
          ..write('runId: $runId, ')
          ..write('status: $status, ')
          ..write('phaseStatus: $phaseStatus, ')
          ..write('currentPhaseIndex: $currentPhaseIndex, ')
          ..write('repeatIndex: $repeatIndex, ')
          ..write('accumulatedMs: $accumulatedMs, ')
          ..write('phaseStartedAtUtc: $phaseStartedAtUtc, ')
          ..write('pausedAtUtc: $pausedAtUtc, ')
          ..write('stateVersion: $stateVersion, ')
          ..write('lastEventId: $lastEventId, ')
          ..write('routineSnapshotJson: $routineSnapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      runId,
      status,
      phaseStatus,
      currentPhaseIndex,
      repeatIndex,
      accumulatedMs,
      phaseStartedAtUtc,
      pausedAtUtc,
      stateVersion,
      lastEventId,
      routineSnapshotJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerRun &&
          other.runId == this.runId &&
          other.status == this.status &&
          other.phaseStatus == this.phaseStatus &&
          other.currentPhaseIndex == this.currentPhaseIndex &&
          other.repeatIndex == this.repeatIndex &&
          other.accumulatedMs == this.accumulatedMs &&
          other.phaseStartedAtUtc == this.phaseStartedAtUtc &&
          other.pausedAtUtc == this.pausedAtUtc &&
          other.stateVersion == this.stateVersion &&
          other.lastEventId == this.lastEventId &&
          other.routineSnapshotJson == this.routineSnapshotJson);
}

class TimerRunsCompanion extends UpdateCompanion<TimerRun> {
  final Value<String> runId;
  final Value<String> status;
  final Value<String> phaseStatus;
  final Value<int> currentPhaseIndex;
  final Value<int> repeatIndex;
  final Value<int> accumulatedMs;
  final Value<DateTime> phaseStartedAtUtc;
  final Value<DateTime?> pausedAtUtc;
  final Value<int> stateVersion;
  final Value<String?> lastEventId;
  final Value<String> routineSnapshotJson;
  final Value<int> rowid;
  const TimerRunsCompanion({
    this.runId = const Value.absent(),
    this.status = const Value.absent(),
    this.phaseStatus = const Value.absent(),
    this.currentPhaseIndex = const Value.absent(),
    this.repeatIndex = const Value.absent(),
    this.accumulatedMs = const Value.absent(),
    this.phaseStartedAtUtc = const Value.absent(),
    this.pausedAtUtc = const Value.absent(),
    this.stateVersion = const Value.absent(),
    this.lastEventId = const Value.absent(),
    this.routineSnapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimerRunsCompanion.insert({
    required String runId,
    required String status,
    required String phaseStatus,
    required int currentPhaseIndex,
    required int repeatIndex,
    required int accumulatedMs,
    required DateTime phaseStartedAtUtc,
    this.pausedAtUtc = const Value.absent(),
    required int stateVersion,
    this.lastEventId = const Value.absent(),
    required String routineSnapshotJson,
    this.rowid = const Value.absent(),
  })  : runId = Value(runId),
        status = Value(status),
        phaseStatus = Value(phaseStatus),
        currentPhaseIndex = Value(currentPhaseIndex),
        repeatIndex = Value(repeatIndex),
        accumulatedMs = Value(accumulatedMs),
        phaseStartedAtUtc = Value(phaseStartedAtUtc),
        stateVersion = Value(stateVersion),
        routineSnapshotJson = Value(routineSnapshotJson);
  static Insertable<TimerRun> custom({
    Expression<String>? runId,
    Expression<String>? status,
    Expression<String>? phaseStatus,
    Expression<int>? currentPhaseIndex,
    Expression<int>? repeatIndex,
    Expression<int>? accumulatedMs,
    Expression<DateTime>? phaseStartedAtUtc,
    Expression<DateTime>? pausedAtUtc,
    Expression<int>? stateVersion,
    Expression<String>? lastEventId,
    Expression<String>? routineSnapshotJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (status != null) 'status': status,
      if (phaseStatus != null) 'phase_status': phaseStatus,
      if (currentPhaseIndex != null) 'current_phase_index': currentPhaseIndex,
      if (repeatIndex != null) 'repeat_index': repeatIndex,
      if (accumulatedMs != null) 'accumulated_ms': accumulatedMs,
      if (phaseStartedAtUtc != null) 'phase_started_at_utc': phaseStartedAtUtc,
      if (pausedAtUtc != null) 'paused_at_utc': pausedAtUtc,
      if (stateVersion != null) 'state_version': stateVersion,
      if (lastEventId != null) 'last_event_id': lastEventId,
      if (routineSnapshotJson != null)
        'routine_snapshot_json': routineSnapshotJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimerRunsCompanion copyWith(
      {Value<String>? runId,
      Value<String>? status,
      Value<String>? phaseStatus,
      Value<int>? currentPhaseIndex,
      Value<int>? repeatIndex,
      Value<int>? accumulatedMs,
      Value<DateTime>? phaseStartedAtUtc,
      Value<DateTime?>? pausedAtUtc,
      Value<int>? stateVersion,
      Value<String?>? lastEventId,
      Value<String>? routineSnapshotJson,
      Value<int>? rowid}) {
    return TimerRunsCompanion(
      runId: runId ?? this.runId,
      status: status ?? this.status,
      phaseStatus: phaseStatus ?? this.phaseStatus,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      repeatIndex: repeatIndex ?? this.repeatIndex,
      accumulatedMs: accumulatedMs ?? this.accumulatedMs,
      phaseStartedAtUtc: phaseStartedAtUtc ?? this.phaseStartedAtUtc,
      pausedAtUtc: pausedAtUtc ?? this.pausedAtUtc,
      stateVersion: stateVersion ?? this.stateVersion,
      lastEventId: lastEventId ?? this.lastEventId,
      routineSnapshotJson: routineSnapshotJson ?? this.routineSnapshotJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (phaseStatus.present) {
      map['phase_status'] = Variable<String>(phaseStatus.value);
    }
    if (currentPhaseIndex.present) {
      map['current_phase_index'] = Variable<int>(currentPhaseIndex.value);
    }
    if (repeatIndex.present) {
      map['repeat_index'] = Variable<int>(repeatIndex.value);
    }
    if (accumulatedMs.present) {
      map['accumulated_ms'] = Variable<int>(accumulatedMs.value);
    }
    if (phaseStartedAtUtc.present) {
      map['phase_started_at_utc'] = Variable<DateTime>(phaseStartedAtUtc.value);
    }
    if (pausedAtUtc.present) {
      map['paused_at_utc'] = Variable<DateTime>(pausedAtUtc.value);
    }
    if (stateVersion.present) {
      map['state_version'] = Variable<int>(stateVersion.value);
    }
    if (lastEventId.present) {
      map['last_event_id'] = Variable<String>(lastEventId.value);
    }
    if (routineSnapshotJson.present) {
      map['routine_snapshot_json'] =
          Variable<String>(routineSnapshotJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerRunsCompanion(')
          ..write('runId: $runId, ')
          ..write('status: $status, ')
          ..write('phaseStatus: $phaseStatus, ')
          ..write('currentPhaseIndex: $currentPhaseIndex, ')
          ..write('repeatIndex: $repeatIndex, ')
          ..write('accumulatedMs: $accumulatedMs, ')
          ..write('phaseStartedAtUtc: $phaseStartedAtUtc, ')
          ..write('pausedAtUtc: $pausedAtUtc, ')
          ..write('stateVersion: $stateVersion, ')
          ..write('lastEventId: $lastEventId, ')
          ..write('routineSnapshotJson: $routineSnapshotJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerEventsTable extends TimerEvents
    with TableInfo<$TimerEventsTable, TimerEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
      'run_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES timer_runs (run_id) ON DELETE CASCADE'));
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtUtcMeta =
      const VerificationMeta('occurredAtUtc');
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>('occurred_at_utc', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns =>
      [eventId, runId, eventType, occurredAtUtc, durationMs, metadataJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_events';
  @override
  VerificationContext validateIntegrity(Insertable<TimerEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
          _runIdMeta, runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta));
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
          _occurredAtUtcMeta,
          occurredAtUtc.isAcceptableOrUnknown(
              data['occurred_at_utc']!, _occurredAtUtcMeta));
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  TimerEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerEvent(
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      runId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}run_id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}occurred_at_utc'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json'])!,
    );
  }

  @override
  $TimerEventsTable createAlias(String alias) {
    return $TimerEventsTable(attachedDatabase, alias);
  }
}

class TimerEvent extends DataClass implements Insertable<TimerEvent> {
  final String eventId;
  final String runId;
  final String eventType;
  final DateTime occurredAtUtc;
  final int durationMs;
  final String metadataJson;
  const TimerEvent(
      {required this.eventId,
      required this.runId,
      required this.eventType,
      required this.occurredAtUtc,
      required this.durationMs,
      required this.metadataJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['run_id'] = Variable<String>(runId);
    map['event_type'] = Variable<String>(eventType);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['duration_ms'] = Variable<int>(durationMs);
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  TimerEventsCompanion toCompanion(bool nullToAbsent) {
    return TimerEventsCompanion(
      eventId: Value(eventId),
      runId: Value(runId),
      eventType: Value(eventType),
      occurredAtUtc: Value(occurredAtUtc),
      durationMs: Value(durationMs),
      metadataJson: Value(metadataJson),
    );
  }

  factory TimerEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      runId: serializer.fromJson<String>(json['runId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'runId': serializer.toJson<String>(runId),
      'eventType': serializer.toJson<String>(eventType),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'durationMs': serializer.toJson<int>(durationMs),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  TimerEvent copyWith(
          {String? eventId,
          String? runId,
          String? eventType,
          DateTime? occurredAtUtc,
          int? durationMs,
          String? metadataJson}) =>
      TimerEvent(
        eventId: eventId ?? this.eventId,
        runId: runId ?? this.runId,
        eventType: eventType ?? this.eventType,
        occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
        durationMs: durationMs ?? this.durationMs,
        metadataJson: metadataJson ?? this.metadataJson,
      );
  TimerEvent copyWithCompanion(TimerEventsCompanion data) {
    return TimerEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      runId: data.runId.present ? data.runId.value : this.runId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerEvent(')
          ..write('eventId: $eventId, ')
          ..write('runId: $runId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('durationMs: $durationMs, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      eventId, runId, eventType, occurredAtUtc, durationMs, metadataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerEvent &&
          other.eventId == this.eventId &&
          other.runId == this.runId &&
          other.eventType == this.eventType &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.durationMs == this.durationMs &&
          other.metadataJson == this.metadataJson);
}

class TimerEventsCompanion extends UpdateCompanion<TimerEvent> {
  final Value<String> eventId;
  final Value<String> runId;
  final Value<String> eventType;
  final Value<DateTime> occurredAtUtc;
  final Value<int> durationMs;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const TimerEventsCompanion({
    this.eventId = const Value.absent(),
    this.runId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimerEventsCompanion.insert({
    required String eventId,
    required String runId,
    required String eventType,
    required DateTime occurredAtUtc,
    this.durationMs = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : eventId = Value(eventId),
        runId = Value(runId),
        eventType = Value(eventType),
        occurredAtUtc = Value(occurredAtUtc);
  static Insertable<TimerEvent> custom({
    Expression<String>? eventId,
    Expression<String>? runId,
    Expression<String>? eventType,
    Expression<DateTime>? occurredAtUtc,
    Expression<int>? durationMs,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (runId != null) 'run_id': runId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (durationMs != null) 'duration_ms': durationMs,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimerEventsCompanion copyWith(
      {Value<String>? eventId,
      Value<String>? runId,
      Value<String>? eventType,
      Value<DateTime>? occurredAtUtc,
      Value<int>? durationMs,
      Value<String>? metadataJson,
      Value<int>? rowid}) {
    return TimerEventsCompanion(
      eventId: eventId ?? this.eventId,
      runId: runId ?? this.runId,
      eventType: eventType ?? this.eventType,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      durationMs: durationMs ?? this.durationMs,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('runId: $runId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('durationMs: $durationMs, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planBlockIdMeta =
      const VerificationMeta('planBlockId');
  @override
  late final GeneratedColumn<String> planBlockId = GeneratedColumn<String>(
      'plan_block_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routineNameMeta =
      const VerificationMeta('routineName');
  @override
  late final GeneratedColumn<String> routineName = GeneratedColumn<String>(
      'routine_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtUtcMeta =
      const VerificationMeta('startedAtUtc');
  @override
  late final GeneratedColumn<DateTime> startedAtUtc = GeneratedColumn<DateTime>(
      'started_at_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtUtcMeta =
      const VerificationMeta('endedAtUtc');
  @override
  late final GeneratedColumn<DateTime> endedAtUtc = GeneratedColumn<DateTime>(
      'ended_at_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalDurationMsMeta =
      const VerificationMeta('totalDurationMs');
  @override
  late final GeneratedColumn<int> totalDurationMs = GeneratedColumn<int>(
      'total_duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _outcomeMeta =
      const VerificationMeta('outcome');
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
      'outcome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routineSnapshotJsonMeta =
      const VerificationMeta('routineSnapshotJson');
  @override
  late final GeneratedColumn<String> routineSnapshotJson =
      GeneratedColumn<String>('routine_snapshot_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        routineId,
        planBlockId,
        routineName,
        startedAtUtc,
        endedAtUtc,
        totalDurationMs,
        outcome,
        routineSnapshotJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    }
    if (data.containsKey('plan_block_id')) {
      context.handle(
          _planBlockIdMeta,
          planBlockId.isAcceptableOrUnknown(
              data['plan_block_id']!, _planBlockIdMeta));
    }
    if (data.containsKey('routine_name')) {
      context.handle(
          _routineNameMeta,
          routineName.isAcceptableOrUnknown(
              data['routine_name']!, _routineNameMeta));
    } else if (isInserting) {
      context.missing(_routineNameMeta);
    }
    if (data.containsKey('started_at_utc')) {
      context.handle(
          _startedAtUtcMeta,
          startedAtUtc.isAcceptableOrUnknown(
              data['started_at_utc']!, _startedAtUtcMeta));
    } else if (isInserting) {
      context.missing(_startedAtUtcMeta);
    }
    if (data.containsKey('ended_at_utc')) {
      context.handle(
          _endedAtUtcMeta,
          endedAtUtc.isAcceptableOrUnknown(
              data['ended_at_utc']!, _endedAtUtcMeta));
    } else if (isInserting) {
      context.missing(_endedAtUtcMeta);
    }
    if (data.containsKey('total_duration_ms')) {
      context.handle(
          _totalDurationMsMeta,
          totalDurationMs.isAcceptableOrUnknown(
              data['total_duration_ms']!, _totalDurationMsMeta));
    } else if (isInserting) {
      context.missing(_totalDurationMsMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta,
          outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('routine_snapshot_json')) {
      context.handle(
          _routineSnapshotJsonMeta,
          routineSnapshotJson.isAcceptableOrUnknown(
              data['routine_snapshot_json']!, _routineSnapshotJsonMeta));
    } else if (isInserting) {
      context.missing(_routineSnapshotJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id']),
      planBlockId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_block_id']),
      routineName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_name'])!,
      startedAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}started_at_utc'])!,
      endedAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at_utc'])!,
      totalDurationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_duration_ms'])!,
      outcome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}outcome'])!,
      routineSnapshotJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}routine_snapshot_json'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String sessionId;
  final String? routineId;
  final String? planBlockId;
  final String routineName;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final int totalDurationMs;
  final String outcome;
  final String routineSnapshotJson;
  const Session(
      {required this.sessionId,
      this.routineId,
      this.planBlockId,
      required this.routineName,
      required this.startedAtUtc,
      required this.endedAtUtc,
      required this.totalDurationMs,
      required this.outcome,
      required this.routineSnapshotJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    if (!nullToAbsent || planBlockId != null) {
      map['plan_block_id'] = Variable<String>(planBlockId);
    }
    map['routine_name'] = Variable<String>(routineName);
    map['started_at_utc'] = Variable<DateTime>(startedAtUtc);
    map['ended_at_utc'] = Variable<DateTime>(endedAtUtc);
    map['total_duration_ms'] = Variable<int>(totalDurationMs);
    map['outcome'] = Variable<String>(outcome);
    map['routine_snapshot_json'] = Variable<String>(routineSnapshotJson);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      sessionId: Value(sessionId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      planBlockId: planBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(planBlockId),
      routineName: Value(routineName),
      startedAtUtc: Value(startedAtUtc),
      endedAtUtc: Value(endedAtUtc),
      totalDurationMs: Value(totalDurationMs),
      outcome: Value(outcome),
      routineSnapshotJson: Value(routineSnapshotJson),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      planBlockId: serializer.fromJson<String?>(json['planBlockId']),
      routineName: serializer.fromJson<String>(json['routineName']),
      startedAtUtc: serializer.fromJson<DateTime>(json['startedAtUtc']),
      endedAtUtc: serializer.fromJson<DateTime>(json['endedAtUtc']),
      totalDurationMs: serializer.fromJson<int>(json['totalDurationMs']),
      outcome: serializer.fromJson<String>(json['outcome']),
      routineSnapshotJson:
          serializer.fromJson<String>(json['routineSnapshotJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'routineId': serializer.toJson<String?>(routineId),
      'planBlockId': serializer.toJson<String?>(planBlockId),
      'routineName': serializer.toJson<String>(routineName),
      'startedAtUtc': serializer.toJson<DateTime>(startedAtUtc),
      'endedAtUtc': serializer.toJson<DateTime>(endedAtUtc),
      'totalDurationMs': serializer.toJson<int>(totalDurationMs),
      'outcome': serializer.toJson<String>(outcome),
      'routineSnapshotJson': serializer.toJson<String>(routineSnapshotJson),
    };
  }

  Session copyWith(
          {String? sessionId,
          Value<String?> routineId = const Value.absent(),
          Value<String?> planBlockId = const Value.absent(),
          String? routineName,
          DateTime? startedAtUtc,
          DateTime? endedAtUtc,
          int? totalDurationMs,
          String? outcome,
          String? routineSnapshotJson}) =>
      Session(
        sessionId: sessionId ?? this.sessionId,
        routineId: routineId.present ? routineId.value : this.routineId,
        planBlockId: planBlockId.present ? planBlockId.value : this.planBlockId,
        routineName: routineName ?? this.routineName,
        startedAtUtc: startedAtUtc ?? this.startedAtUtc,
        endedAtUtc: endedAtUtc ?? this.endedAtUtc,
        totalDurationMs: totalDurationMs ?? this.totalDurationMs,
        outcome: outcome ?? this.outcome,
        routineSnapshotJson: routineSnapshotJson ?? this.routineSnapshotJson,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      planBlockId:
          data.planBlockId.present ? data.planBlockId.value : this.planBlockId,
      routineName:
          data.routineName.present ? data.routineName.value : this.routineName,
      startedAtUtc: data.startedAtUtc.present
          ? data.startedAtUtc.value
          : this.startedAtUtc,
      endedAtUtc:
          data.endedAtUtc.present ? data.endedAtUtc.value : this.endedAtUtc,
      totalDurationMs: data.totalDurationMs.present
          ? data.totalDurationMs.value
          : this.totalDurationMs,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      routineSnapshotJson: data.routineSnapshotJson.present
          ? data.routineSnapshotJson.value
          : this.routineSnapshotJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('sessionId: $sessionId, ')
          ..write('routineId: $routineId, ')
          ..write('planBlockId: $planBlockId, ')
          ..write('routineName: $routineName, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('endedAtUtc: $endedAtUtc, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('outcome: $outcome, ')
          ..write('routineSnapshotJson: $routineSnapshotJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId,
      routineId,
      planBlockId,
      routineName,
      startedAtUtc,
      endedAtUtc,
      totalDurationMs,
      outcome,
      routineSnapshotJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.sessionId == this.sessionId &&
          other.routineId == this.routineId &&
          other.planBlockId == this.planBlockId &&
          other.routineName == this.routineName &&
          other.startedAtUtc == this.startedAtUtc &&
          other.endedAtUtc == this.endedAtUtc &&
          other.totalDurationMs == this.totalDurationMs &&
          other.outcome == this.outcome &&
          other.routineSnapshotJson == this.routineSnapshotJson);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> sessionId;
  final Value<String?> routineId;
  final Value<String?> planBlockId;
  final Value<String> routineName;
  final Value<DateTime> startedAtUtc;
  final Value<DateTime> endedAtUtc;
  final Value<int> totalDurationMs;
  final Value<String> outcome;
  final Value<String> routineSnapshotJson;
  final Value<int> rowid;
  const SessionsCompanion({
    this.sessionId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.planBlockId = const Value.absent(),
    this.routineName = const Value.absent(),
    this.startedAtUtc = const Value.absent(),
    this.endedAtUtc = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.outcome = const Value.absent(),
    this.routineSnapshotJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String sessionId,
    this.routineId = const Value.absent(),
    this.planBlockId = const Value.absent(),
    required String routineName,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    required int totalDurationMs,
    required String outcome,
    required String routineSnapshotJson,
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        routineName = Value(routineName),
        startedAtUtc = Value(startedAtUtc),
        endedAtUtc = Value(endedAtUtc),
        totalDurationMs = Value(totalDurationMs),
        outcome = Value(outcome),
        routineSnapshotJson = Value(routineSnapshotJson);
  static Insertable<Session> custom({
    Expression<String>? sessionId,
    Expression<String>? routineId,
    Expression<String>? planBlockId,
    Expression<String>? routineName,
    Expression<DateTime>? startedAtUtc,
    Expression<DateTime>? endedAtUtc,
    Expression<int>? totalDurationMs,
    Expression<String>? outcome,
    Expression<String>? routineSnapshotJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (routineId != null) 'routine_id': routineId,
      if (planBlockId != null) 'plan_block_id': planBlockId,
      if (routineName != null) 'routine_name': routineName,
      if (startedAtUtc != null) 'started_at_utc': startedAtUtc,
      if (endedAtUtc != null) 'ended_at_utc': endedAtUtc,
      if (totalDurationMs != null) 'total_duration_ms': totalDurationMs,
      if (outcome != null) 'outcome': outcome,
      if (routineSnapshotJson != null)
        'routine_snapshot_json': routineSnapshotJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? sessionId,
      Value<String?>? routineId,
      Value<String?>? planBlockId,
      Value<String>? routineName,
      Value<DateTime>? startedAtUtc,
      Value<DateTime>? endedAtUtc,
      Value<int>? totalDurationMs,
      Value<String>? outcome,
      Value<String>? routineSnapshotJson,
      Value<int>? rowid}) {
    return SessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      routineId: routineId ?? this.routineId,
      planBlockId: planBlockId ?? this.planBlockId,
      routineName: routineName ?? this.routineName,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      endedAtUtc: endedAtUtc ?? this.endedAtUtc,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      outcome: outcome ?? this.outcome,
      routineSnapshotJson: routineSnapshotJson ?? this.routineSnapshotJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (planBlockId.present) {
      map['plan_block_id'] = Variable<String>(planBlockId.value);
    }
    if (routineName.present) {
      map['routine_name'] = Variable<String>(routineName.value);
    }
    if (startedAtUtc.present) {
      map['started_at_utc'] = Variable<DateTime>(startedAtUtc.value);
    }
    if (endedAtUtc.present) {
      map['ended_at_utc'] = Variable<DateTime>(endedAtUtc.value);
    }
    if (totalDurationMs.present) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (routineSnapshotJson.present) {
      map['routine_snapshot_json'] =
          Variable<String>(routineSnapshotJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('routineId: $routineId, ')
          ..write('planBlockId: $planBlockId, ')
          ..write('routineName: $routineName, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('endedAtUtc: $endedAtUtc, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('outcome: $outcome, ')
          ..write('routineSnapshotJson: $routineSnapshotJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionEventsTable extends SessionEvents
    with TableInfo<$SessionEventsTable, SessionEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES sessions (session_id) ON DELETE CASCADE'));
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtUtcMeta =
      const VerificationMeta('occurredAtUtc');
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>('occurred_at_utc', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _phaseIdMeta =
      const VerificationMeta('phaseId');
  @override
  late final GeneratedColumn<String> phaseId = GeneratedColumn<String>(
      'phase_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phaseNameMeta =
      const VerificationMeta('phaseName');
  @override
  late final GeneratedColumn<String> phaseName = GeneratedColumn<String>(
      'phase_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _outcomeMeta =
      const VerificationMeta('outcome');
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
      'outcome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        eventId,
        sessionId,
        eventType,
        occurredAtUtc,
        phaseId,
        phaseName,
        durationMs,
        outcome
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_events';
  @override
  VerificationContext validateIntegrity(Insertable<SessionEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
          _occurredAtUtcMeta,
          occurredAtUtc.isAcceptableOrUnknown(
              data['occurred_at_utc']!, _occurredAtUtcMeta));
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('phase_id')) {
      context.handle(_phaseIdMeta,
          phaseId.isAcceptableOrUnknown(data['phase_id']!, _phaseIdMeta));
    }
    if (data.containsKey('phase_name')) {
      context.handle(_phaseNameMeta,
          phaseName.isAcceptableOrUnknown(data['phase_name']!, _phaseNameMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta,
          outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  SessionEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionEvent(
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}occurred_at_utc'])!,
      phaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phase_id']),
      phaseName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phase_name']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      outcome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}outcome']),
    );
  }

  @override
  $SessionEventsTable createAlias(String alias) {
    return $SessionEventsTable(attachedDatabase, alias);
  }
}

class SessionEvent extends DataClass implements Insertable<SessionEvent> {
  final String eventId;
  final String sessionId;
  final String eventType;
  final DateTime occurredAtUtc;
  final String? phaseId;
  final String? phaseName;
  final int durationMs;
  final String? outcome;
  const SessionEvent(
      {required this.eventId,
      required this.sessionId,
      required this.eventType,
      required this.occurredAtUtc,
      this.phaseId,
      this.phaseName,
      required this.durationMs,
      this.outcome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['session_id'] = Variable<String>(sessionId);
    map['event_type'] = Variable<String>(eventType);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    if (!nullToAbsent || phaseId != null) {
      map['phase_id'] = Variable<String>(phaseId);
    }
    if (!nullToAbsent || phaseName != null) {
      map['phase_name'] = Variable<String>(phaseName);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    return map;
  }

  SessionEventsCompanion toCompanion(bool nullToAbsent) {
    return SessionEventsCompanion(
      eventId: Value(eventId),
      sessionId: Value(sessionId),
      eventType: Value(eventType),
      occurredAtUtc: Value(occurredAtUtc),
      phaseId: phaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(phaseId),
      phaseName: phaseName == null && nullToAbsent
          ? const Value.absent()
          : Value(phaseName),
      durationMs: Value(durationMs),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
    );
  }

  factory SessionEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      phaseId: serializer.fromJson<String?>(json['phaseId']),
      phaseName: serializer.fromJson<String?>(json['phaseName']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      outcome: serializer.fromJson<String?>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'sessionId': serializer.toJson<String>(sessionId),
      'eventType': serializer.toJson<String>(eventType),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'phaseId': serializer.toJson<String?>(phaseId),
      'phaseName': serializer.toJson<String?>(phaseName),
      'durationMs': serializer.toJson<int>(durationMs),
      'outcome': serializer.toJson<String?>(outcome),
    };
  }

  SessionEvent copyWith(
          {String? eventId,
          String? sessionId,
          String? eventType,
          DateTime? occurredAtUtc,
          Value<String?> phaseId = const Value.absent(),
          Value<String?> phaseName = const Value.absent(),
          int? durationMs,
          Value<String?> outcome = const Value.absent()}) =>
      SessionEvent(
        eventId: eventId ?? this.eventId,
        sessionId: sessionId ?? this.sessionId,
        eventType: eventType ?? this.eventType,
        occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
        phaseId: phaseId.present ? phaseId.value : this.phaseId,
        phaseName: phaseName.present ? phaseName.value : this.phaseName,
        durationMs: durationMs ?? this.durationMs,
        outcome: outcome.present ? outcome.value : this.outcome,
      );
  SessionEvent copyWithCompanion(SessionEventsCompanion data) {
    return SessionEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      phaseId: data.phaseId.present ? data.phaseId.value : this.phaseId,
      phaseName: data.phaseName.present ? data.phaseName.value : this.phaseName,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionEvent(')
          ..write('eventId: $eventId, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('phaseId: $phaseId, ')
          ..write('phaseName: $phaseName, ')
          ..write('durationMs: $durationMs, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, sessionId, eventType, occurredAtUtc,
      phaseId, phaseName, durationMs, outcome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionEvent &&
          other.eventId == this.eventId &&
          other.sessionId == this.sessionId &&
          other.eventType == this.eventType &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.phaseId == this.phaseId &&
          other.phaseName == this.phaseName &&
          other.durationMs == this.durationMs &&
          other.outcome == this.outcome);
}

class SessionEventsCompanion extends UpdateCompanion<SessionEvent> {
  final Value<String> eventId;
  final Value<String> sessionId;
  final Value<String> eventType;
  final Value<DateTime> occurredAtUtc;
  final Value<String?> phaseId;
  final Value<String?> phaseName;
  final Value<int> durationMs;
  final Value<String?> outcome;
  final Value<int> rowid;
  const SessionEventsCompanion({
    this.eventId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.phaseId = const Value.absent(),
    this.phaseName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionEventsCompanion.insert({
    required String eventId,
    required String sessionId,
    required String eventType,
    required DateTime occurredAtUtc,
    this.phaseId = const Value.absent(),
    this.phaseName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : eventId = Value(eventId),
        sessionId = Value(sessionId),
        eventType = Value(eventType),
        occurredAtUtc = Value(occurredAtUtc);
  static Insertable<SessionEvent> custom({
    Expression<String>? eventId,
    Expression<String>? sessionId,
    Expression<String>? eventType,
    Expression<DateTime>? occurredAtUtc,
    Expression<String>? phaseId,
    Expression<String>? phaseName,
    Expression<int>? durationMs,
    Expression<String>? outcome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (sessionId != null) 'session_id': sessionId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (phaseId != null) 'phase_id': phaseId,
      if (phaseName != null) 'phase_name': phaseName,
      if (durationMs != null) 'duration_ms': durationMs,
      if (outcome != null) 'outcome': outcome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionEventsCompanion copyWith(
      {Value<String>? eventId,
      Value<String>? sessionId,
      Value<String>? eventType,
      Value<DateTime>? occurredAtUtc,
      Value<String?>? phaseId,
      Value<String?>? phaseName,
      Value<int>? durationMs,
      Value<String?>? outcome,
      Value<int>? rowid}) {
    return SessionEventsCompanion(
      eventId: eventId ?? this.eventId,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      phaseId: phaseId ?? this.phaseId,
      phaseName: phaseName ?? this.phaseName,
      durationMs: durationMs ?? this.durationMs,
      outcome: outcome ?? this.outcome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (phaseId.present) {
      map['phase_id'] = Variable<String>(phaseId.value);
    }
    if (phaseName.present) {
      map['phase_name'] = Variable<String>(phaseName.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('phaseId: $phaseId, ')
          ..write('phaseName: $phaseName, ')
          ..write('durationMs: $durationMs, ')
          ..write('outcome: $outcome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanBlocksTable extends PlanBlocks
    with TableInfo<$PlanBlocksTable, PlanBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planDateMeta =
      const VerificationMeta('planDate');
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
      'plan_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledStartUtcMeta =
      const VerificationMeta('scheduledStartUtc');
  @override
  late final GeneratedColumn<DateTime> scheduledStartUtc =
      GeneratedColumn<DateTime>('scheduled_start_utc', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _timezoneIdMeta =
      const VerificationMeta('timezoneId');
  @override
  late final GeneratedColumn<String> timezoneId = GeneratedColumn<String>(
      'timezone_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _plannedDurationMsMeta =
      const VerificationMeta('plannedDurationMs');
  @override
  late final GeneratedColumn<int> plannedDurationMs = GeneratedColumn<int>(
      'planned_duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actualDurationMsMeta =
      const VerificationMeta('actualDurationMs');
  @override
  late final GeneratedColumn<int> actualDurationMs = GeneratedColumn<int>(
      'actual_duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planDate,
        scheduledStartUtc,
        timezoneId,
        plannedDurationMs,
        routineId,
        actualDurationMs,
        sessionId,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<PlanBlock> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_date')) {
      context.handle(_planDateMeta,
          planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta));
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('scheduled_start_utc')) {
      context.handle(
          _scheduledStartUtcMeta,
          scheduledStartUtc.isAcceptableOrUnknown(
              data['scheduled_start_utc']!, _scheduledStartUtcMeta));
    } else if (isInserting) {
      context.missing(_scheduledStartUtcMeta);
    }
    if (data.containsKey('timezone_id')) {
      context.handle(
          _timezoneIdMeta,
          timezoneId.isAcceptableOrUnknown(
              data['timezone_id']!, _timezoneIdMeta));
    } else if (isInserting) {
      context.missing(_timezoneIdMeta);
    }
    if (data.containsKey('planned_duration_ms')) {
      context.handle(
          _plannedDurationMsMeta,
          plannedDurationMs.isAcceptableOrUnknown(
              data['planned_duration_ms']!, _plannedDurationMsMeta));
    } else if (isInserting) {
      context.missing(_plannedDurationMsMeta);
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    }
    if (data.containsKey('actual_duration_ms')) {
      context.handle(
          _actualDurationMsMeta,
          actualDurationMs.isAcceptableOrUnknown(
              data['actual_duration_ms']!, _actualDurationMsMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanBlock(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      planDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_date'])!,
      scheduledStartUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}scheduled_start_utc'])!,
      timezoneId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone_id'])!,
      plannedDurationMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}planned_duration_ms'])!,
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id']),
      actualDurationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}actual_duration_ms']),
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $PlanBlocksTable createAlias(String alias) {
    return $PlanBlocksTable(attachedDatabase, alias);
  }
}

class PlanBlock extends DataClass implements Insertable<PlanBlock> {
  final String id;
  final String planDate;
  final DateTime scheduledStartUtc;
  final String timezoneId;
  final int plannedDurationMs;
  final String? routineId;
  final int? actualDurationMs;
  final String? sessionId;
  final String status;
  const PlanBlock(
      {required this.id,
      required this.planDate,
      required this.scheduledStartUtc,
      required this.timezoneId,
      required this.plannedDurationMs,
      this.routineId,
      this.actualDurationMs,
      this.sessionId,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_date'] = Variable<String>(planDate);
    map['scheduled_start_utc'] = Variable<DateTime>(scheduledStartUtc);
    map['timezone_id'] = Variable<String>(timezoneId);
    map['planned_duration_ms'] = Variable<int>(plannedDurationMs);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    if (!nullToAbsent || actualDurationMs != null) {
      map['actual_duration_ms'] = Variable<int>(actualDurationMs);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  PlanBlocksCompanion toCompanion(bool nullToAbsent) {
    return PlanBlocksCompanion(
      id: Value(id),
      planDate: Value(planDate),
      scheduledStartUtc: Value(scheduledStartUtc),
      timezoneId: Value(timezoneId),
      plannedDurationMs: Value(plannedDurationMs),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      actualDurationMs: actualDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDurationMs),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      status: Value(status),
    );
  }

  factory PlanBlock.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanBlock(
      id: serializer.fromJson<String>(json['id']),
      planDate: serializer.fromJson<String>(json['planDate']),
      scheduledStartUtc:
          serializer.fromJson<DateTime>(json['scheduledStartUtc']),
      timezoneId: serializer.fromJson<String>(json['timezoneId']),
      plannedDurationMs: serializer.fromJson<int>(json['plannedDurationMs']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      actualDurationMs: serializer.fromJson<int?>(json['actualDurationMs']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planDate': serializer.toJson<String>(planDate),
      'scheduledStartUtc': serializer.toJson<DateTime>(scheduledStartUtc),
      'timezoneId': serializer.toJson<String>(timezoneId),
      'plannedDurationMs': serializer.toJson<int>(plannedDurationMs),
      'routineId': serializer.toJson<String?>(routineId),
      'actualDurationMs': serializer.toJson<int?>(actualDurationMs),
      'sessionId': serializer.toJson<String?>(sessionId),
      'status': serializer.toJson<String>(status),
    };
  }

  PlanBlock copyWith(
          {String? id,
          String? planDate,
          DateTime? scheduledStartUtc,
          String? timezoneId,
          int? plannedDurationMs,
          Value<String?> routineId = const Value.absent(),
          Value<int?> actualDurationMs = const Value.absent(),
          Value<String?> sessionId = const Value.absent(),
          String? status}) =>
      PlanBlock(
        id: id ?? this.id,
        planDate: planDate ?? this.planDate,
        scheduledStartUtc: scheduledStartUtc ?? this.scheduledStartUtc,
        timezoneId: timezoneId ?? this.timezoneId,
        plannedDurationMs: plannedDurationMs ?? this.plannedDurationMs,
        routineId: routineId.present ? routineId.value : this.routineId,
        actualDurationMs: actualDurationMs.present
            ? actualDurationMs.value
            : this.actualDurationMs,
        sessionId: sessionId.present ? sessionId.value : this.sessionId,
        status: status ?? this.status,
      );
  PlanBlock copyWithCompanion(PlanBlocksCompanion data) {
    return PlanBlock(
      id: data.id.present ? data.id.value : this.id,
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      scheduledStartUtc: data.scheduledStartUtc.present
          ? data.scheduledStartUtc.value
          : this.scheduledStartUtc,
      timezoneId:
          data.timezoneId.present ? data.timezoneId.value : this.timezoneId,
      plannedDurationMs: data.plannedDurationMs.present
          ? data.plannedDurationMs.value
          : this.plannedDurationMs,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      actualDurationMs: data.actualDurationMs.present
          ? data.actualDurationMs.value
          : this.actualDurationMs,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanBlock(')
          ..write('id: $id, ')
          ..write('planDate: $planDate, ')
          ..write('scheduledStartUtc: $scheduledStartUtc, ')
          ..write('timezoneId: $timezoneId, ')
          ..write('plannedDurationMs: $plannedDurationMs, ')
          ..write('routineId: $routineId, ')
          ..write('actualDurationMs: $actualDurationMs, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, planDate, scheduledStartUtc, timezoneId,
      plannedDurationMs, routineId, actualDurationMs, sessionId, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanBlock &&
          other.id == this.id &&
          other.planDate == this.planDate &&
          other.scheduledStartUtc == this.scheduledStartUtc &&
          other.timezoneId == this.timezoneId &&
          other.plannedDurationMs == this.plannedDurationMs &&
          other.routineId == this.routineId &&
          other.actualDurationMs == this.actualDurationMs &&
          other.sessionId == this.sessionId &&
          other.status == this.status);
}

class PlanBlocksCompanion extends UpdateCompanion<PlanBlock> {
  final Value<String> id;
  final Value<String> planDate;
  final Value<DateTime> scheduledStartUtc;
  final Value<String> timezoneId;
  final Value<int> plannedDurationMs;
  final Value<String?> routineId;
  final Value<int?> actualDurationMs;
  final Value<String?> sessionId;
  final Value<String> status;
  final Value<int> rowid;
  const PlanBlocksCompanion({
    this.id = const Value.absent(),
    this.planDate = const Value.absent(),
    this.scheduledStartUtc = const Value.absent(),
    this.timezoneId = const Value.absent(),
    this.plannedDurationMs = const Value.absent(),
    this.routineId = const Value.absent(),
    this.actualDurationMs = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanBlocksCompanion.insert({
    required String id,
    required String planDate,
    required DateTime scheduledStartUtc,
    required String timezoneId,
    required int plannedDurationMs,
    this.routineId = const Value.absent(),
    this.actualDurationMs = const Value.absent(),
    this.sessionId = const Value.absent(),
    required String status,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        planDate = Value(planDate),
        scheduledStartUtc = Value(scheduledStartUtc),
        timezoneId = Value(timezoneId),
        plannedDurationMs = Value(plannedDurationMs),
        status = Value(status);
  static Insertable<PlanBlock> custom({
    Expression<String>? id,
    Expression<String>? planDate,
    Expression<DateTime>? scheduledStartUtc,
    Expression<String>? timezoneId,
    Expression<int>? plannedDurationMs,
    Expression<String>? routineId,
    Expression<int>? actualDurationMs,
    Expression<String>? sessionId,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDate != null) 'plan_date': planDate,
      if (scheduledStartUtc != null) 'scheduled_start_utc': scheduledStartUtc,
      if (timezoneId != null) 'timezone_id': timezoneId,
      if (plannedDurationMs != null) 'planned_duration_ms': plannedDurationMs,
      if (routineId != null) 'routine_id': routineId,
      if (actualDurationMs != null) 'actual_duration_ms': actualDurationMs,
      if (sessionId != null) 'session_id': sessionId,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanBlocksCompanion copyWith(
      {Value<String>? id,
      Value<String>? planDate,
      Value<DateTime>? scheduledStartUtc,
      Value<String>? timezoneId,
      Value<int>? plannedDurationMs,
      Value<String?>? routineId,
      Value<int?>? actualDurationMs,
      Value<String?>? sessionId,
      Value<String>? status,
      Value<int>? rowid}) {
    return PlanBlocksCompanion(
      id: id ?? this.id,
      planDate: planDate ?? this.planDate,
      scheduledStartUtc: scheduledStartUtc ?? this.scheduledStartUtc,
      timezoneId: timezoneId ?? this.timezoneId,
      plannedDurationMs: plannedDurationMs ?? this.plannedDurationMs,
      routineId: routineId ?? this.routineId,
      actualDurationMs: actualDurationMs ?? this.actualDurationMs,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (scheduledStartUtc.present) {
      map['scheduled_start_utc'] = Variable<DateTime>(scheduledStartUtc.value);
    }
    if (timezoneId.present) {
      map['timezone_id'] = Variable<String>(timezoneId.value);
    }
    if (plannedDurationMs.present) {
      map['planned_duration_ms'] = Variable<int>(plannedDurationMs.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (actualDurationMs.present) {
      map['actual_duration_ms'] = Variable<int>(actualDurationMs.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanBlocksCompanion(')
          ..write('id: $id, ')
          ..write('planDate: $planDate, ')
          ..write('scheduledStartUtc: $scheduledStartUtc, ')
          ..write('timezoneId: $timezoneId, ')
          ..write('plannedDurationMs: $plannedDurationMs, ')
          ..write('routineId: $routineId, ')
          ..write('actualDurationMs: $actualDurationMs, ')
          ..write('sessionId: $sessionId, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$DitiDatabase extends GeneratedDatabase {
  _$DitiDatabase(QueryExecutor e) : super(e);
  $DitiDatabaseManager get managers => $DitiDatabaseManager(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutinePhasesTable routinePhases = $RoutinePhasesTable(this);
  late final $TimerRunsTable timerRuns = $TimerRunsTable(this);
  late final $TimerEventsTable timerEvents = $TimerEventsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionEventsTable sessionEvents = $SessionEventsTable(this);
  late final $PlanBlocksTable planBlocks = $PlanBlocksTable(this);
  late final RoutinesDao routinesDao = RoutinesDao(this as DitiDatabase);
  late final TimerRunsDao timerRunsDao = TimerRunsDao(this as DitiDatabase);
  late final SessionsDao sessionsDao = SessionsDao(this as DitiDatabase);
  late final PlanBlocksDao planBlocksDao = PlanBlocksDao(this as DitiDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        routines,
        routinePhases,
        timerRuns,
        timerEvents,
        sessions,
        sessionEvents,
        planBlocks
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('routines',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('routine_phases', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('timer_runs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('timer_events', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('sessions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('session_events', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  required String id,
  required String name,
  required String repeatMode,
  Value<int?> repeatCount,
  required DateTime createdAtUtc,
  required DateTime updatedAtUtc,
  Value<int> rowid,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> repeatMode,
  Value<int?> repeatCount,
  Value<DateTime> createdAtUtc,
  Value<DateTime> updatedAtUtc,
  Value<int> rowid,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$DitiDatabase, $RoutinesTable, Routine> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutinePhasesTable, List<RoutinePhase>>
      _routinePhasesRefsTable(_$DitiDatabase db) =>
          MultiTypedResultKey.fromTable(db.routinePhases,
              aliasName: 'routines__id__routine_phases__routine_id');

  $$RoutinePhasesTableProcessedTableManager get routinePhasesRefs {
    final manager = $$RoutinePhasesTableTableManager($_db, $_db.routinePhases)
        .filter((f) => f.routineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_routinePhasesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$DitiDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatMode => $composableBuilder(
      column: $table.repeatMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repeatCount => $composableBuilder(
      column: $table.repeatCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
      column: $table.updatedAtUtc, builder: (column) => ColumnFilters(column));

  Expression<bool> routinePhasesRefs(
      Expression<bool> Function($$RoutinePhasesTableFilterComposer f) f) {
    final $$RoutinePhasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routinePhases,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinePhasesTableFilterComposer(
              $db: $db,
              $table: $db.routinePhases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$DitiDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatMode => $composableBuilder(
      column: $table.repeatMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repeatCount => $composableBuilder(
      column: $table.repeatCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
      column: $table.updatedAtUtc,
      builder: (column) => ColumnOrderings(column));
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$DitiDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get repeatMode => $composableBuilder(
      column: $table.repeatMode, builder: (column) => column);

  GeneratedColumn<int> get repeatCount => $composableBuilder(
      column: $table.repeatCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
      column: $table.updatedAtUtc, builder: (column) => column);

  Expression<T> routinePhasesRefs<T extends Object>(
      Expression<T> Function($$RoutinePhasesTableAnnotationComposer a) f) {
    final $$RoutinePhasesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routinePhases,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinePhasesTableAnnotationComposer(
              $db: $db,
              $table: $db.routinePhases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $RoutinesTable,
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool routinePhasesRefs})> {
  $$RoutinesTableTableManager(_$DitiDatabase db, $RoutinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> repeatMode = const Value.absent(),
            Value<int?> repeatCount = const Value.absent(),
            Value<DateTime> createdAtUtc = const Value.absent(),
            Value<DateTime> updatedAtUtc = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinesCompanion(
            id: id,
            name: name,
            repeatMode: repeatMode,
            repeatCount: repeatCount,
            createdAtUtc: createdAtUtc,
            updatedAtUtc: updatedAtUtc,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String repeatMode,
            Value<int?> repeatCount = const Value.absent(),
            required DateTime createdAtUtc,
            required DateTime updatedAtUtc,
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinesCompanion.insert(
            id: id,
            name: name,
            repeatMode: repeatMode,
            repeatCount: repeatCount,
            createdAtUtc: createdAtUtc,
            updatedAtUtc: updatedAtUtc,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoutinesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({routinePhasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routinePhasesRefs) db.routinePhases
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routinePhasesRefs)
                    await $_getPrefetchedData<Routine, $RoutinesTable,
                            RoutinePhase>(
                        currentTable: table,
                        referencedTable: $$RoutinesTableReferences
                            ._routinePhasesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .routinePhasesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.routineId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutinesTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $RoutinesTable,
    Routine,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (Routine, $$RoutinesTableReferences),
    Routine,
    PrefetchHooks Function({bool routinePhasesRefs})>;
typedef $$RoutinePhasesTableCreateCompanionBuilder = RoutinePhasesCompanion
    Function({
  required String id,
  required String routineId,
  required int orderIndex,
  required String name,
  Value<int?> durationMs,
  required String transitionPolicy,
  Value<int> rowid,
});
typedef $$RoutinePhasesTableUpdateCompanionBuilder = RoutinePhasesCompanion
    Function({
  Value<String> id,
  Value<String> routineId,
  Value<int> orderIndex,
  Value<String> name,
  Value<int?> durationMs,
  Value<String> transitionPolicy,
  Value<int> rowid,
});

final class $$RoutinePhasesTableReferences
    extends BaseReferences<_$DitiDatabase, $RoutinePhasesTable, RoutinePhase> {
  $$RoutinePhasesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$DitiDatabase db) =>
      db.routines.createAlias('routine_phases__routine_id__routines__id');

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<String>('routine_id')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RoutinePhasesTableFilterComposer
    extends Composer<_$DitiDatabase, $RoutinePhasesTable> {
  $$RoutinePhasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transitionPolicy => $composableBuilder(
      column: $table.transitionPolicy,
      builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableFilterComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutinePhasesTableOrderingComposer
    extends Composer<_$DitiDatabase, $RoutinePhasesTable> {
  $$RoutinePhasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transitionPolicy => $composableBuilder(
      column: $table.transitionPolicy,
      builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableOrderingComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutinePhasesTableAnnotationComposer
    extends Composer<_$DitiDatabase, $RoutinePhasesTable> {
  $$RoutinePhasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get transitionPolicy => $composableBuilder(
      column: $table.transitionPolicy, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableAnnotationComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutinePhasesTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $RoutinePhasesTable,
    RoutinePhase,
    $$RoutinePhasesTableFilterComposer,
    $$RoutinePhasesTableOrderingComposer,
    $$RoutinePhasesTableAnnotationComposer,
    $$RoutinePhasesTableCreateCompanionBuilder,
    $$RoutinePhasesTableUpdateCompanionBuilder,
    (RoutinePhase, $$RoutinePhasesTableReferences),
    RoutinePhase,
    PrefetchHooks Function({bool routineId})> {
  $$RoutinePhasesTableTableManager(_$DitiDatabase db, $RoutinePhasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinePhasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinePhasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinePhasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> routineId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<String> transitionPolicy = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinePhasesCompanion(
            id: id,
            routineId: routineId,
            orderIndex: orderIndex,
            name: name,
            durationMs: durationMs,
            transitionPolicy: transitionPolicy,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String routineId,
            required int orderIndex,
            required String name,
            Value<int?> durationMs = const Value.absent(),
            required String transitionPolicy,
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinePhasesCompanion.insert(
            id: id,
            routineId: routineId,
            orderIndex: orderIndex,
            name: name,
            durationMs: durationMs,
            transitionPolicy: transitionPolicy,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RoutinePhasesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (routineId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routineId,
                    referencedTable:
                        $$RoutinePhasesTableReferences._routineIdTable(db),
                    referencedColumn:
                        $$RoutinePhasesTableReferences._routineIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RoutinePhasesTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $RoutinePhasesTable,
    RoutinePhase,
    $$RoutinePhasesTableFilterComposer,
    $$RoutinePhasesTableOrderingComposer,
    $$RoutinePhasesTableAnnotationComposer,
    $$RoutinePhasesTableCreateCompanionBuilder,
    $$RoutinePhasesTableUpdateCompanionBuilder,
    (RoutinePhase, $$RoutinePhasesTableReferences),
    RoutinePhase,
    PrefetchHooks Function({bool routineId})>;
typedef $$TimerRunsTableCreateCompanionBuilder = TimerRunsCompanion Function({
  required String runId,
  required String status,
  required String phaseStatus,
  required int currentPhaseIndex,
  required int repeatIndex,
  required int accumulatedMs,
  required DateTime phaseStartedAtUtc,
  Value<DateTime?> pausedAtUtc,
  required int stateVersion,
  Value<String?> lastEventId,
  required String routineSnapshotJson,
  Value<int> rowid,
});
typedef $$TimerRunsTableUpdateCompanionBuilder = TimerRunsCompanion Function({
  Value<String> runId,
  Value<String> status,
  Value<String> phaseStatus,
  Value<int> currentPhaseIndex,
  Value<int> repeatIndex,
  Value<int> accumulatedMs,
  Value<DateTime> phaseStartedAtUtc,
  Value<DateTime?> pausedAtUtc,
  Value<int> stateVersion,
  Value<String?> lastEventId,
  Value<String> routineSnapshotJson,
  Value<int> rowid,
});

final class $$TimerRunsTableReferences
    extends BaseReferences<_$DitiDatabase, $TimerRunsTable, TimerRun> {
  $$TimerRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TimerEventsTable, List<TimerEvent>>
      _timerEventsRefsTable(_$DitiDatabase db) =>
          MultiTypedResultKey.fromTable(db.timerEvents,
              aliasName: 'timer_runs__run_id__timer_events__run_id');

  $$TimerEventsTableProcessedTableManager get timerEventsRefs {
    final manager = $$TimerEventsTableTableManager($_db, $_db.timerEvents)
        .filter(
            (f) => f.runId.runId.sqlEquals($_itemColumn<String>('run_id')!));

    final cache = $_typedResult.readTableOrNull(_timerEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TimerRunsTableFilterComposer
    extends Composer<_$DitiDatabase, $TimerRunsTable> {
  $$TimerRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get runId => $composableBuilder(
      column: $table.runId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phaseStatus => $composableBuilder(
      column: $table.phaseStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentPhaseIndex => $composableBuilder(
      column: $table.currentPhaseIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repeatIndex => $composableBuilder(
      column: $table.repeatIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accumulatedMs => $composableBuilder(
      column: $table.accumulatedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get phaseStartedAtUtc => $composableBuilder(
      column: $table.phaseStartedAtUtc,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pausedAtUtc => $composableBuilder(
      column: $table.pausedAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stateVersion => $composableBuilder(
      column: $table.stateVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastEventId => $composableBuilder(
      column: $table.lastEventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineSnapshotJson => $composableBuilder(
      column: $table.routineSnapshotJson,
      builder: (column) => ColumnFilters(column));

  Expression<bool> timerEventsRefs(
      Expression<bool> Function($$TimerEventsTableFilterComposer f) f) {
    final $$TimerEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.runId,
        referencedTable: $db.timerEvents,
        getReferencedColumn: (t) => t.runId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimerEventsTableFilterComposer(
              $db: $db,
              $table: $db.timerEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TimerRunsTableOrderingComposer
    extends Composer<_$DitiDatabase, $TimerRunsTable> {
  $$TimerRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get runId => $composableBuilder(
      column: $table.runId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phaseStatus => $composableBuilder(
      column: $table.phaseStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentPhaseIndex => $composableBuilder(
      column: $table.currentPhaseIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repeatIndex => $composableBuilder(
      column: $table.repeatIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accumulatedMs => $composableBuilder(
      column: $table.accumulatedMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get phaseStartedAtUtc => $composableBuilder(
      column: $table.phaseStartedAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pausedAtUtc => $composableBuilder(
      column: $table.pausedAtUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stateVersion => $composableBuilder(
      column: $table.stateVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastEventId => $composableBuilder(
      column: $table.lastEventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineSnapshotJson => $composableBuilder(
      column: $table.routineSnapshotJson,
      builder: (column) => ColumnOrderings(column));
}

class $$TimerRunsTableAnnotationComposer
    extends Composer<_$DitiDatabase, $TimerRunsTable> {
  $$TimerRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get phaseStatus => $composableBuilder(
      column: $table.phaseStatus, builder: (column) => column);

  GeneratedColumn<int> get currentPhaseIndex => $composableBuilder(
      column: $table.currentPhaseIndex, builder: (column) => column);

  GeneratedColumn<int> get repeatIndex => $composableBuilder(
      column: $table.repeatIndex, builder: (column) => column);

  GeneratedColumn<int> get accumulatedMs => $composableBuilder(
      column: $table.accumulatedMs, builder: (column) => column);

  GeneratedColumn<DateTime> get phaseStartedAtUtc => $composableBuilder(
      column: $table.phaseStartedAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAtUtc => $composableBuilder(
      column: $table.pausedAtUtc, builder: (column) => column);

  GeneratedColumn<int> get stateVersion => $composableBuilder(
      column: $table.stateVersion, builder: (column) => column);

  GeneratedColumn<String> get lastEventId => $composableBuilder(
      column: $table.lastEventId, builder: (column) => column);

  GeneratedColumn<String> get routineSnapshotJson => $composableBuilder(
      column: $table.routineSnapshotJson, builder: (column) => column);

  Expression<T> timerEventsRefs<T extends Object>(
      Expression<T> Function($$TimerEventsTableAnnotationComposer a) f) {
    final $$TimerEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.runId,
        referencedTable: $db.timerEvents,
        getReferencedColumn: (t) => t.runId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimerEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.timerEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TimerRunsTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $TimerRunsTable,
    TimerRun,
    $$TimerRunsTableFilterComposer,
    $$TimerRunsTableOrderingComposer,
    $$TimerRunsTableAnnotationComposer,
    $$TimerRunsTableCreateCompanionBuilder,
    $$TimerRunsTableUpdateCompanionBuilder,
    (TimerRun, $$TimerRunsTableReferences),
    TimerRun,
    PrefetchHooks Function({bool timerEventsRefs})> {
  $$TimerRunsTableTableManager(_$DitiDatabase db, $TimerRunsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> runId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> phaseStatus = const Value.absent(),
            Value<int> currentPhaseIndex = const Value.absent(),
            Value<int> repeatIndex = const Value.absent(),
            Value<int> accumulatedMs = const Value.absent(),
            Value<DateTime> phaseStartedAtUtc = const Value.absent(),
            Value<DateTime?> pausedAtUtc = const Value.absent(),
            Value<int> stateVersion = const Value.absent(),
            Value<String?> lastEventId = const Value.absent(),
            Value<String> routineSnapshotJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerRunsCompanion(
            runId: runId,
            status: status,
            phaseStatus: phaseStatus,
            currentPhaseIndex: currentPhaseIndex,
            repeatIndex: repeatIndex,
            accumulatedMs: accumulatedMs,
            phaseStartedAtUtc: phaseStartedAtUtc,
            pausedAtUtc: pausedAtUtc,
            stateVersion: stateVersion,
            lastEventId: lastEventId,
            routineSnapshotJson: routineSnapshotJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String runId,
            required String status,
            required String phaseStatus,
            required int currentPhaseIndex,
            required int repeatIndex,
            required int accumulatedMs,
            required DateTime phaseStartedAtUtc,
            Value<DateTime?> pausedAtUtc = const Value.absent(),
            required int stateVersion,
            Value<String?> lastEventId = const Value.absent(),
            required String routineSnapshotJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerRunsCompanion.insert(
            runId: runId,
            status: status,
            phaseStatus: phaseStatus,
            currentPhaseIndex: currentPhaseIndex,
            repeatIndex: repeatIndex,
            accumulatedMs: accumulatedMs,
            phaseStartedAtUtc: phaseStartedAtUtc,
            pausedAtUtc: pausedAtUtc,
            stateVersion: stateVersion,
            lastEventId: lastEventId,
            routineSnapshotJson: routineSnapshotJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TimerRunsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({timerEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (timerEventsRefs) db.timerEvents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (timerEventsRefs)
                    await $_getPrefetchedData<TimerRun, $TimerRunsTable,
                            TimerEvent>(
                        currentTable: table,
                        referencedTable: $$TimerRunsTableReferences
                            ._timerEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TimerRunsTableReferences(db, table, p0)
                                .timerEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.runId == item.runId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TimerRunsTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $TimerRunsTable,
    TimerRun,
    $$TimerRunsTableFilterComposer,
    $$TimerRunsTableOrderingComposer,
    $$TimerRunsTableAnnotationComposer,
    $$TimerRunsTableCreateCompanionBuilder,
    $$TimerRunsTableUpdateCompanionBuilder,
    (TimerRun, $$TimerRunsTableReferences),
    TimerRun,
    PrefetchHooks Function({bool timerEventsRefs})>;
typedef $$TimerEventsTableCreateCompanionBuilder = TimerEventsCompanion
    Function({
  required String eventId,
  required String runId,
  required String eventType,
  required DateTime occurredAtUtc,
  Value<int> durationMs,
  Value<String> metadataJson,
  Value<int> rowid,
});
typedef $$TimerEventsTableUpdateCompanionBuilder = TimerEventsCompanion
    Function({
  Value<String> eventId,
  Value<String> runId,
  Value<String> eventType,
  Value<DateTime> occurredAtUtc,
  Value<int> durationMs,
  Value<String> metadataJson,
  Value<int> rowid,
});

final class $$TimerEventsTableReferences
    extends BaseReferences<_$DitiDatabase, $TimerEventsTable, TimerEvent> {
  $$TimerEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TimerRunsTable _runIdTable(_$DitiDatabase db) =>
      db.timerRuns.createAlias('timer_events__run_id__timer_runs__run_id');

  $$TimerRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$TimerRunsTableTableManager($_db, $_db.timerRuns)
        .filter((f) => f.runId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TimerEventsTableFilterComposer
    extends Composer<_$DitiDatabase, $TimerEventsTable> {
  $$TimerEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  $$TimerRunsTableFilterComposer get runId {
    final $$TimerRunsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.runId,
        referencedTable: $db.timerRuns,
        getReferencedColumn: (t) => t.runId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimerRunsTableFilterComposer(
              $db: $db,
              $table: $db.timerRuns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimerEventsTableOrderingComposer
    extends Composer<_$DitiDatabase, $TimerEventsTable> {
  $$TimerEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  $$TimerRunsTableOrderingComposer get runId {
    final $$TimerRunsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.runId,
        referencedTable: $db.timerRuns,
        getReferencedColumn: (t) => t.runId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimerRunsTableOrderingComposer(
              $db: $db,
              $table: $db.timerRuns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimerEventsTableAnnotationComposer
    extends Composer<_$DitiDatabase, $TimerEventsTable> {
  $$TimerEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  $$TimerRunsTableAnnotationComposer get runId {
    final $$TimerRunsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.runId,
        referencedTable: $db.timerRuns,
        getReferencedColumn: (t) => t.runId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TimerRunsTableAnnotationComposer(
              $db: $db,
              $table: $db.timerRuns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TimerEventsTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $TimerEventsTable,
    TimerEvent,
    $$TimerEventsTableFilterComposer,
    $$TimerEventsTableOrderingComposer,
    $$TimerEventsTableAnnotationComposer,
    $$TimerEventsTableCreateCompanionBuilder,
    $$TimerEventsTableUpdateCompanionBuilder,
    (TimerEvent, $$TimerEventsTableReferences),
    TimerEvent,
    PrefetchHooks Function({bool runId})> {
  $$TimerEventsTableTableManager(_$DitiDatabase db, $TimerEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> eventId = const Value.absent(),
            Value<String> runId = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<DateTime> occurredAtUtc = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerEventsCompanion(
            eventId: eventId,
            runId: runId,
            eventType: eventType,
            occurredAtUtc: occurredAtUtc,
            durationMs: durationMs,
            metadataJson: metadataJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String eventId,
            required String runId,
            required String eventType,
            required DateTime occurredAtUtc,
            Value<int> durationMs = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerEventsCompanion.insert(
            eventId: eventId,
            runId: runId,
            eventType: eventType,
            occurredAtUtc: occurredAtUtc,
            durationMs: durationMs,
            metadataJson: metadataJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TimerEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (runId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.runId,
                    referencedTable:
                        $$TimerEventsTableReferences._runIdTable(db),
                    referencedColumn:
                        $$TimerEventsTableReferences._runIdTable(db).runId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TimerEventsTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $TimerEventsTable,
    TimerEvent,
    $$TimerEventsTableFilterComposer,
    $$TimerEventsTableOrderingComposer,
    $$TimerEventsTableAnnotationComposer,
    $$TimerEventsTableCreateCompanionBuilder,
    $$TimerEventsTableUpdateCompanionBuilder,
    (TimerEvent, $$TimerEventsTableReferences),
    TimerEvent,
    PrefetchHooks Function({bool runId})>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String sessionId,
  Value<String?> routineId,
  Value<String?> planBlockId,
  required String routineName,
  required DateTime startedAtUtc,
  required DateTime endedAtUtc,
  required int totalDurationMs,
  required String outcome,
  required String routineSnapshotJson,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> sessionId,
  Value<String?> routineId,
  Value<String?> planBlockId,
  Value<String> routineName,
  Value<DateTime> startedAtUtc,
  Value<DateTime> endedAtUtc,
  Value<int> totalDurationMs,
  Value<String> outcome,
  Value<String> routineSnapshotJson,
  Value<int> rowid,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$DitiDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionEventsTable, List<SessionEvent>>
      _sessionEventsRefsTable(_$DitiDatabase db) =>
          MultiTypedResultKey.fromTable(db.sessionEvents,
              aliasName: 'sessions__session_id__session_events__session_id');

  $$SessionEventsTableProcessedTableManager get sessionEventsRefs {
    final manager = $$SessionEventsTableTableManager($_db, $_db.sessionEvents)
        .filter((f) => f.sessionId.sessionId
            .sqlEquals($_itemColumn<String>('session_id')!));

    final cache = $_typedResult.readTableOrNull(_sessionEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$DitiDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planBlockId => $composableBuilder(
      column: $table.planBlockId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineName => $composableBuilder(
      column: $table.routineName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAtUtc => $composableBuilder(
      column: $table.startedAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAtUtc => $composableBuilder(
      column: $table.endedAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDurationMs => $composableBuilder(
      column: $table.totalDurationMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineSnapshotJson => $composableBuilder(
      column: $table.routineSnapshotJson,
      builder: (column) => ColumnFilters(column));

  Expression<bool> sessionEventsRefs(
      Expression<bool> Function($$SessionEventsTableFilterComposer f) f) {
    final $$SessionEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessionEvents,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionEventsTableFilterComposer(
              $db: $db,
              $table: $db.sessionEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$DitiDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planBlockId => $composableBuilder(
      column: $table.planBlockId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineName => $composableBuilder(
      column: $table.routineName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAtUtc => $composableBuilder(
      column: $table.startedAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAtUtc => $composableBuilder(
      column: $table.endedAtUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDurationMs => $composableBuilder(
      column: $table.totalDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineSnapshotJson => $composableBuilder(
      column: $table.routineSnapshotJson,
      builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$DitiDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get planBlockId => $composableBuilder(
      column: $table.planBlockId, builder: (column) => column);

  GeneratedColumn<String> get routineName => $composableBuilder(
      column: $table.routineName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAtUtc => $composableBuilder(
      column: $table.startedAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAtUtc => $composableBuilder(
      column: $table.endedAtUtc, builder: (column) => column);

  GeneratedColumn<int> get totalDurationMs => $composableBuilder(
      column: $table.totalDurationMs, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get routineSnapshotJson => $composableBuilder(
      column: $table.routineSnapshotJson, builder: (column) => column);

  Expression<T> sessionEventsRefs<T extends Object>(
      Expression<T> Function($$SessionEventsTableAnnotationComposer a) f) {
    final $$SessionEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessionEvents,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessionEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SessionsTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, $$SessionsTableReferences),
    Session,
    PrefetchHooks Function({bool sessionEventsRefs})> {
  $$SessionsTableTableManager(_$DitiDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<String?> planBlockId = const Value.absent(),
            Value<String> routineName = const Value.absent(),
            Value<DateTime> startedAtUtc = const Value.absent(),
            Value<DateTime> endedAtUtc = const Value.absent(),
            Value<int> totalDurationMs = const Value.absent(),
            Value<String> outcome = const Value.absent(),
            Value<String> routineSnapshotJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            sessionId: sessionId,
            routineId: routineId,
            planBlockId: planBlockId,
            routineName: routineName,
            startedAtUtc: startedAtUtc,
            endedAtUtc: endedAtUtc,
            totalDurationMs: totalDurationMs,
            outcome: outcome,
            routineSnapshotJson: routineSnapshotJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionId,
            Value<String?> routineId = const Value.absent(),
            Value<String?> planBlockId = const Value.absent(),
            required String routineName,
            required DateTime startedAtUtc,
            required DateTime endedAtUtc,
            required int totalDurationMs,
            required String outcome,
            required String routineSnapshotJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            sessionId: sessionId,
            routineId: routineId,
            planBlockId: planBlockId,
            routineName: routineName,
            startedAtUtc: startedAtUtc,
            endedAtUtc: endedAtUtc,
            totalDurationMs: totalDurationMs,
            outcome: outcome,
            routineSnapshotJson: routineSnapshotJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SessionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({sessionEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionEventsRefs) db.sessionEvents
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionEventsRefs)
                    await $_getPrefetchedData<Session, $SessionsTable,
                            SessionEvent>(
                        currentTable: table,
                        referencedTable: $$SessionsTableReferences
                            ._sessionEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SessionsTableReferences(db, table, p0)
                                .sessionEventsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.sessionId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, $$SessionsTableReferences),
    Session,
    PrefetchHooks Function({bool sessionEventsRefs})>;
typedef $$SessionEventsTableCreateCompanionBuilder = SessionEventsCompanion
    Function({
  required String eventId,
  required String sessionId,
  required String eventType,
  required DateTime occurredAtUtc,
  Value<String?> phaseId,
  Value<String?> phaseName,
  Value<int> durationMs,
  Value<String?> outcome,
  Value<int> rowid,
});
typedef $$SessionEventsTableUpdateCompanionBuilder = SessionEventsCompanion
    Function({
  Value<String> eventId,
  Value<String> sessionId,
  Value<String> eventType,
  Value<DateTime> occurredAtUtc,
  Value<String?> phaseId,
  Value<String?> phaseName,
  Value<int> durationMs,
  Value<String?> outcome,
  Value<int> rowid,
});

final class $$SessionEventsTableReferences
    extends BaseReferences<_$DitiDatabase, $SessionEventsTable, SessionEvent> {
  $$SessionEventsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$DitiDatabase db) => db.sessions
      .createAlias('session_events__session_id__sessions__session_id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager($_db, $_db.sessions)
        .filter((f) => f.sessionId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SessionEventsTableFilterComposer
    extends Composer<_$DitiDatabase, $SessionEventsTable> {
  $$SessionEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phaseId => $composableBuilder(
      column: $table.phaseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phaseName => $composableBuilder(
      column: $table.phaseName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnFilters(column));

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableFilterComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionEventsTableOrderingComposer
    extends Composer<_$DitiDatabase, $SessionEventsTable> {
  $$SessionEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
      column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phaseId => $composableBuilder(
      column: $table.phaseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phaseName => $composableBuilder(
      column: $table.phaseName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnOrderings(column));

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableOrderingComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionEventsTableAnnotationComposer
    extends Composer<_$DitiDatabase, $SessionEventsTable> {
  $$SessionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
      column: $table.occurredAtUtc, builder: (column) => column);

  GeneratedColumn<String> get phaseId =>
      $composableBuilder(column: $table.phaseId, builder: (column) => column);

  GeneratedColumn<String> get phaseName =>
      $composableBuilder(column: $table.phaseName, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.sessions,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.sessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SessionEventsTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $SessionEventsTable,
    SessionEvent,
    $$SessionEventsTableFilterComposer,
    $$SessionEventsTableOrderingComposer,
    $$SessionEventsTableAnnotationComposer,
    $$SessionEventsTableCreateCompanionBuilder,
    $$SessionEventsTableUpdateCompanionBuilder,
    (SessionEvent, $$SessionEventsTableReferences),
    SessionEvent,
    PrefetchHooks Function({bool sessionId})> {
  $$SessionEventsTableTableManager(_$DitiDatabase db, $SessionEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> eventId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<DateTime> occurredAtUtc = const Value.absent(),
            Value<String?> phaseId = const Value.absent(),
            Value<String?> phaseName = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String?> outcome = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionEventsCompanion(
            eventId: eventId,
            sessionId: sessionId,
            eventType: eventType,
            occurredAtUtc: occurredAtUtc,
            phaseId: phaseId,
            phaseName: phaseName,
            durationMs: durationMs,
            outcome: outcome,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String eventId,
            required String sessionId,
            required String eventType,
            required DateTime occurredAtUtc,
            Value<String?> phaseId = const Value.absent(),
            Value<String?> phaseName = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String?> outcome = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionEventsCompanion.insert(
            eventId: eventId,
            sessionId: sessionId,
            eventType: eventType,
            occurredAtUtc: occurredAtUtc,
            phaseId: phaseId,
            phaseName: phaseName,
            durationMs: durationMs,
            outcome: outcome,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SessionEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$SessionEventsTableReferences._sessionIdTable(db),
                    referencedColumn: $$SessionEventsTableReferences
                        ._sessionIdTable(db)
                        .sessionId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SessionEventsTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $SessionEventsTable,
    SessionEvent,
    $$SessionEventsTableFilterComposer,
    $$SessionEventsTableOrderingComposer,
    $$SessionEventsTableAnnotationComposer,
    $$SessionEventsTableCreateCompanionBuilder,
    $$SessionEventsTableUpdateCompanionBuilder,
    (SessionEvent, $$SessionEventsTableReferences),
    SessionEvent,
    PrefetchHooks Function({bool sessionId})>;
typedef $$PlanBlocksTableCreateCompanionBuilder = PlanBlocksCompanion Function({
  required String id,
  required String planDate,
  required DateTime scheduledStartUtc,
  required String timezoneId,
  required int plannedDurationMs,
  Value<String?> routineId,
  Value<int?> actualDurationMs,
  Value<String?> sessionId,
  required String status,
  Value<int> rowid,
});
typedef $$PlanBlocksTableUpdateCompanionBuilder = PlanBlocksCompanion Function({
  Value<String> id,
  Value<String> planDate,
  Value<DateTime> scheduledStartUtc,
  Value<String> timezoneId,
  Value<int> plannedDurationMs,
  Value<String?> routineId,
  Value<int?> actualDurationMs,
  Value<String?> sessionId,
  Value<String> status,
  Value<int> rowid,
});

class $$PlanBlocksTableFilterComposer
    extends Composer<_$DitiDatabase, $PlanBlocksTable> {
  $$PlanBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledStartUtc => $composableBuilder(
      column: $table.scheduledStartUtc,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezoneId => $composableBuilder(
      column: $table.timezoneId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedDurationMs => $composableBuilder(
      column: $table.plannedDurationMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get actualDurationMs => $composableBuilder(
      column: $table.actualDurationMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$PlanBlocksTableOrderingComposer
    extends Composer<_$DitiDatabase, $PlanBlocksTable> {
  $$PlanBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledStartUtc => $composableBuilder(
      column: $table.scheduledStartUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezoneId => $composableBuilder(
      column: $table.timezoneId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedDurationMs => $composableBuilder(
      column: $table.plannedDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get actualDurationMs => $composableBuilder(
      column: $table.actualDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$PlanBlocksTableAnnotationComposer
    extends Composer<_$DitiDatabase, $PlanBlocksTable> {
  $$PlanBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledStartUtc => $composableBuilder(
      column: $table.scheduledStartUtc, builder: (column) => column);

  GeneratedColumn<String> get timezoneId => $composableBuilder(
      column: $table.timezoneId, builder: (column) => column);

  GeneratedColumn<int> get plannedDurationMs => $composableBuilder(
      column: $table.plannedDurationMs, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<int> get actualDurationMs => $composableBuilder(
      column: $table.actualDurationMs, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$PlanBlocksTableTableManager extends RootTableManager<
    _$DitiDatabase,
    $PlanBlocksTable,
    PlanBlock,
    $$PlanBlocksTableFilterComposer,
    $$PlanBlocksTableOrderingComposer,
    $$PlanBlocksTableAnnotationComposer,
    $$PlanBlocksTableCreateCompanionBuilder,
    $$PlanBlocksTableUpdateCompanionBuilder,
    (PlanBlock, BaseReferences<_$DitiDatabase, $PlanBlocksTable, PlanBlock>),
    PlanBlock,
    PrefetchHooks Function()> {
  $$PlanBlocksTableTableManager(_$DitiDatabase db, $PlanBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> planDate = const Value.absent(),
            Value<DateTime> scheduledStartUtc = const Value.absent(),
            Value<String> timezoneId = const Value.absent(),
            Value<int> plannedDurationMs = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<int?> actualDurationMs = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanBlocksCompanion(
            id: id,
            planDate: planDate,
            scheduledStartUtc: scheduledStartUtc,
            timezoneId: timezoneId,
            plannedDurationMs: plannedDurationMs,
            routineId: routineId,
            actualDurationMs: actualDurationMs,
            sessionId: sessionId,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String planDate,
            required DateTime scheduledStartUtc,
            required String timezoneId,
            required int plannedDurationMs,
            Value<String?> routineId = const Value.absent(),
            Value<int?> actualDurationMs = const Value.absent(),
            Value<String?> sessionId = const Value.absent(),
            required String status,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanBlocksCompanion.insert(
            id: id,
            planDate: planDate,
            scheduledStartUtc: scheduledStartUtc,
            timezoneId: timezoneId,
            plannedDurationMs: plannedDurationMs,
            routineId: routineId,
            actualDurationMs: actualDurationMs,
            sessionId: sessionId,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanBlocksTableProcessedTableManager = ProcessedTableManager<
    _$DitiDatabase,
    $PlanBlocksTable,
    PlanBlock,
    $$PlanBlocksTableFilterComposer,
    $$PlanBlocksTableOrderingComposer,
    $$PlanBlocksTableAnnotationComposer,
    $$PlanBlocksTableCreateCompanionBuilder,
    $$PlanBlocksTableUpdateCompanionBuilder,
    (PlanBlock, BaseReferences<_$DitiDatabase, $PlanBlocksTable, PlanBlock>),
    PlanBlock,
    PrefetchHooks Function()>;

class $DitiDatabaseManager {
  final _$DitiDatabase _db;
  $DitiDatabaseManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutinePhasesTableTableManager get routinePhases =>
      $$RoutinePhasesTableTableManager(_db, _db.routinePhases);
  $$TimerRunsTableTableManager get timerRuns =>
      $$TimerRunsTableTableManager(_db, _db.timerRuns);
  $$TimerEventsTableTableManager get timerEvents =>
      $$TimerEventsTableTableManager(_db, _db.timerEvents);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionEventsTableTableManager get sessionEvents =>
      $$SessionEventsTableTableManager(_db, _db.sessionEvents);
  $$PlanBlocksTableTableManager get planBlocks =>
      $$PlanBlocksTableTableManager(_db, _db.planBlocks);
}
