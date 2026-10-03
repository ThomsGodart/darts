// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SoireesTable extends Soirees
    with TableInfo<$SoireesTable, StoredSoiree> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoireesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soirees';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSoiree> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredSoiree map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSoiree(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SoireesTable createAlias(String alias) {
    return $SoireesTable(attachedDatabase, alias);
  }
}

class StoredSoiree extends DataClass implements Insertable<StoredSoiree> {
  final int id;
  final DateTime createdAt;
  const StoredSoiree({required this.id, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SoireesCompanion toCompanion(bool nullToAbsent) {
    return SoireesCompanion(id: Value(id), createdAt: Value(createdAt));
  }

  factory StoredSoiree.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSoiree(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StoredSoiree copyWith({int? id, DateTime? createdAt}) =>
      StoredSoiree(id: id ?? this.id, createdAt: createdAt ?? this.createdAt);
  StoredSoiree copyWithCompanion(SoireesCompanion data) {
    return StoredSoiree(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSoiree(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSoiree &&
          other.id == this.id &&
          other.createdAt == this.createdAt);
}

class SoireesCompanion extends UpdateCompanion<StoredSoiree> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  const SoireesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SoireesCompanion.insert({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  static Insertable<StoredSoiree> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SoireesCompanion copyWith({Value<int>? id, Value<DateTime>? createdAt}) {
    return SoireesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoireesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SoireeEventsTable extends SoireeEvents
    with TableInfo<$SoireeEventsTable, StoredEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoireeEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _soireeIdMeta = const VerificationMeta(
    'soireeId',
  );
  @override
  late final GeneratedColumn<int> soireeId = GeneratedColumn<int>(
    'soiree_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES soirees (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    soireeId,
    seq,
    type,
    payload,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soiree_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('soiree_id')) {
      context.handle(
        _soireeIdMeta,
        soireeId.isAcceptableOrUnknown(data['soiree_id']!, _soireeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_soireeIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {soireeId, seq};
  @override
  StoredEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredEvent(
      soireeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}soiree_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $SoireeEventsTable createAlias(String alias) {
    return $SoireeEventsTable(attachedDatabase, alias);
  }
}

class StoredEvent extends DataClass implements Insertable<StoredEvent> {
  final int soireeId;

  /// Position of the event in its soirée's journal, from 0.
  final int seq;
  final String type;

  /// The event's fields as JSON.
  final String payload;
  final DateTime recordedAt;
  const StoredEvent({
    required this.soireeId,
    required this.seq,
    required this.type,
    required this.payload,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['soiree_id'] = Variable<int>(soireeId);
    map['seq'] = Variable<int>(seq);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  SoireeEventsCompanion toCompanion(bool nullToAbsent) {
    return SoireeEventsCompanion(
      soireeId: Value(soireeId),
      seq: Value(seq),
      type: Value(type),
      payload: Value(payload),
      recordedAt: Value(recordedAt),
    );
  }

  factory StoredEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredEvent(
      soireeId: serializer.fromJson<int>(json['soireeId']),
      seq: serializer.fromJson<int>(json['seq']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'soireeId': serializer.toJson<int>(soireeId),
      'seq': serializer.toJson<int>(seq),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  StoredEvent copyWith({
    int? soireeId,
    int? seq,
    String? type,
    String? payload,
    DateTime? recordedAt,
  }) => StoredEvent(
    soireeId: soireeId ?? this.soireeId,
    seq: seq ?? this.seq,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  StoredEvent copyWithCompanion(SoireeEventsCompanion data) {
    return StoredEvent(
      soireeId: data.soireeId.present ? data.soireeId.value : this.soireeId,
      seq: data.seq.present ? data.seq.value : this.seq,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredEvent(')
          ..write('soireeId: $soireeId, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(soireeId, seq, type, payload, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredEvent &&
          other.soireeId == this.soireeId &&
          other.seq == this.seq &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.recordedAt == this.recordedAt);
}

class SoireeEventsCompanion extends UpdateCompanion<StoredEvent> {
  final Value<int> soireeId;
  final Value<int> seq;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const SoireeEventsCompanion({
    this.soireeId = const Value.absent(),
    this.seq = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SoireeEventsCompanion.insert({
    required int soireeId,
    required int seq,
    required String type,
    required String payload,
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : soireeId = Value(soireeId),
       seq = Value(seq),
       type = Value(type),
       payload = Value(payload);
  static Insertable<StoredEvent> custom({
    Expression<int>? soireeId,
    Expression<int>? seq,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (soireeId != null) 'soiree_id': soireeId,
      if (seq != null) 'seq': seq,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SoireeEventsCompanion copyWith({
    Value<int>? soireeId,
    Value<int>? seq,
    Value<String>? type,
    Value<String>? payload,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return SoireeEventsCompanion(
      soireeId: soireeId ?? this.soireeId,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (soireeId.present) {
      map['soiree_id'] = Variable<int>(soireeId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoireeEventsCompanion(')
          ..write('soireeId: $soireeId, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players
    with TableInfo<$PlayersTable, StoredPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasPlayedMeta = const VerificationMeta(
    'hasPlayed',
  );
  @override
  late final GeneratedColumn<bool> hasPlayed = GeneratedColumn<bool>(
    'has_played',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_played" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, archived, hasPlayed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredPlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('has_played')) {
      context.handle(
        _hasPlayedMeta,
        hasPlayed.isAcceptableOrUnknown(data['has_played']!, _hasPlayedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredPlayer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      hasPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_played'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class StoredPlayer extends DataClass implements Insertable<StoredPlayer> {
  final int id;
  final String name;
  final bool archived;
  final bool hasPlayed;
  const StoredPlayer({
    required this.id,
    required this.name,
    required this.archived,
    required this.hasPlayed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['archived'] = Variable<bool>(archived);
    map['has_played'] = Variable<bool>(hasPlayed);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      archived: Value(archived),
      hasPlayed: Value(hasPlayed),
    );
  }

  factory StoredPlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredPlayer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      archived: serializer.fromJson<bool>(json['archived']),
      hasPlayed: serializer.fromJson<bool>(json['hasPlayed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'archived': serializer.toJson<bool>(archived),
      'hasPlayed': serializer.toJson<bool>(hasPlayed),
    };
  }

  StoredPlayer copyWith({
    int? id,
    String? name,
    bool? archived,
    bool? hasPlayed,
  }) => StoredPlayer(
    id: id ?? this.id,
    name: name ?? this.name,
    archived: archived ?? this.archived,
    hasPlayed: hasPlayed ?? this.hasPlayed,
  );
  StoredPlayer copyWithCompanion(PlayersCompanion data) {
    return StoredPlayer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      archived: data.archived.present ? data.archived.value : this.archived,
      hasPlayed: data.hasPlayed.present ? data.hasPlayed.value : this.hasPlayed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredPlayer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('hasPlayed: $hasPlayed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, archived, hasPlayed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredPlayer &&
          other.id == this.id &&
          other.name == this.name &&
          other.archived == this.archived &&
          other.hasPlayed == this.hasPlayed);
}

class PlayersCompanion extends UpdateCompanion<StoredPlayer> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> archived;
  final Value<bool> hasPlayed;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.archived = const Value.absent(),
    this.hasPlayed = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.archived = const Value.absent(),
    this.hasPlayed = const Value.absent(),
  }) : name = Value(name);
  static Insertable<StoredPlayer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? archived,
    Expression<bool>? hasPlayed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (archived != null) 'archived': archived,
      if (hasPlayed != null) 'has_played': hasPlayed,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? archived,
    Value<bool>? hasPlayed,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      archived: archived ?? this.archived,
      hasPlayed: hasPlayed ?? this.hasPlayed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (hasPlayed.present) {
      map['has_played'] = Variable<bool>(hasPlayed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('hasPlayed: $hasPlayed')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SoireesTable soirees = $SoireesTable(this);
  late final $SoireeEventsTable soireeEvents = $SoireeEventsTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    soirees,
    soireeEvents,
    players,
  ];
}

typedef $$SoireesTableCreateCompanionBuilder = SoireesCompanion Function({
  Value<int> id,
  Value<DateTime> createdAt,
});
typedef $$SoireesTableUpdateCompanionBuilder = SoireesCompanion Function({
  Value<int> id,
  Value<DateTime> createdAt,
});

final class $$SoireesTableReferences
    extends BaseReferences<_$AppDatabase, $SoireesTable, StoredSoiree> {
  $$SoireesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SoireeEventsTable, List<StoredEvent>>
  _soireeEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.soireeEvents,
    aliasName: 'soirees__id__soiree_events__soiree_id',
  );

  $$SoireeEventsTableProcessedTableManager get soireeEventsRefs {
    final manager = $$SoireeEventsTableTableManager(
      $_db,
      $_db.soireeEvents,
    ).filter((f) => f.soireeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_soireeEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SoireesTableFilterComposer
    extends Composer<_$AppDatabase, $SoireesTable> {
  $$SoireesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> soireeEventsRefs(
    Expression<bool> Function($$SoireeEventsTableFilterComposer f) f,
  ) {
    final $$SoireeEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.soireeEvents,
      getReferencedColumn: (t) => t.soireeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SoireeEventsTableFilterComposer(
            $db: $db,
            $table: $db.soireeEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SoireesTableOrderingComposer
    extends Composer<_$AppDatabase, $SoireesTable> {
  $$SoireesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SoireesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoireesTable> {
  $$SoireesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> soireeEventsRefs<T extends Object>(
    Expression<T> Function($$SoireeEventsTableAnnotationComposer a) f,
  ) {
    final $$SoireeEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.soireeEvents,
      getReferencedColumn: (t) => t.soireeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SoireeEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.soireeEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SoireesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SoireesTable,
          StoredSoiree,
          $$SoireesTableFilterComposer,
          $$SoireesTableOrderingComposer,
          $$SoireesTableAnnotationComposer,
          $$SoireesTableCreateCompanionBuilder,
          $$SoireesTableUpdateCompanionBuilder,
          (StoredSoiree, $$SoireesTableReferences),
          StoredSoiree,
          PrefetchHooks Function({bool soireeEventsRefs})
        > {
  $$SoireesTableTableManager(_$AppDatabase db, $SoireesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoireesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SoireesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoireesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => SoireesCompanion(id: id, createdAt: createdAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => SoireesCompanion.insert(id: id, createdAt: createdAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SoireesTable, StoredSoiree>(table),
                  $$SoireesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({soireeEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (soireeEventsRefs) db.soireeEvents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (soireeEventsRefs)
                    await $_getPrefetchedData<
                      StoredSoiree,
                      $SoireesTable,
                      StoredEvent
                    >(
                      currentTable: table,
                      referencedTable: $$SoireesTableReferences
                          ._soireeEventsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SoireesTableReferences(
                        db,
                        table,
                        p0,
                      ).soireeEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.soireeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SoireesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SoireesTable,
      StoredSoiree,
      $$SoireesTableFilterComposer,
      $$SoireesTableOrderingComposer,
      $$SoireesTableAnnotationComposer,
      $$SoireesTableCreateCompanionBuilder,
      $$SoireesTableUpdateCompanionBuilder,
      (StoredSoiree, $$SoireesTableReferences),
      StoredSoiree,
      PrefetchHooks Function({bool soireeEventsRefs})
    >;
typedef $$SoireeEventsTableCreateCompanionBuilder =
    SoireeEventsCompanion Function({
      required int soireeId,
      required int seq,
      required String type,
      required String payload,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });
typedef $$SoireeEventsTableUpdateCompanionBuilder =
    SoireeEventsCompanion Function({
      Value<int> soireeId,
      Value<int> seq,
      Value<String> type,
      Value<String> payload,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$SoireeEventsTableReferences
    extends BaseReferences<_$AppDatabase, $SoireeEventsTable, StoredEvent> {
  $$SoireeEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SoireesTable _soireeIdTable(_$AppDatabase db) =>
      db.soirees.createAlias('soiree_events__soiree_id__soirees__id');

  $$SoireesTableProcessedTableManager get soireeId {
    final $_column = $_itemColumn<int>('soiree_id')!;

    final manager = $$SoireesTableTableManager(
      $_db,
      $_db.soirees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_soireeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SoireeEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SoireeEventsTable> {
  $$SoireeEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SoireesTableFilterComposer get soireeId {
    final $$SoireesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.soireeId,
      referencedTable: $db.soirees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SoireesTableFilterComposer(
            $db: $db,
            $table: $db.soirees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SoireeEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SoireeEventsTable> {
  $$SoireeEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SoireesTableOrderingComposer get soireeId {
    final $$SoireesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.soireeId,
      referencedTable: $db.soirees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SoireesTableOrderingComposer(
            $db: $db,
            $table: $db.soirees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SoireeEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SoireeEventsTable> {
  $$SoireeEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$SoireesTableAnnotationComposer get soireeId {
    final $$SoireesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.soireeId,
      referencedTable: $db.soirees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SoireesTableAnnotationComposer(
            $db: $db,
            $table: $db.soirees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SoireeEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SoireeEventsTable,
          StoredEvent,
          $$SoireeEventsTableFilterComposer,
          $$SoireeEventsTableOrderingComposer,
          $$SoireeEventsTableAnnotationComposer,
          $$SoireeEventsTableCreateCompanionBuilder,
          $$SoireeEventsTableUpdateCompanionBuilder,
          (StoredEvent, $$SoireeEventsTableReferences),
          StoredEvent,
          PrefetchHooks Function({bool soireeId})
        > {
  $$SoireeEventsTableTableManager(_$AppDatabase db, $SoireeEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SoireeEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SoireeEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SoireeEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> soireeId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SoireeEventsCompanion(
                soireeId: soireeId,
                seq: seq,
                type: type,
                payload: payload,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int soireeId,
                required int seq,
                required String type,
                required String payload,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SoireeEventsCompanion.insert(
                soireeId: soireeId,
                seq: seq,
                type: type,
                payload: payload,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SoireeEventsTable, StoredEvent>(table),
                  $$SoireeEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({soireeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (soireeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.soireeId,
                        referencedTable: $$SoireeEventsTableReferences
                            ._soireeIdTable(db),
                        referencedColumn: $$SoireeEventsTableReferences
                            ._soireeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SoireeEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SoireeEventsTable,
      StoredEvent,
      $$SoireeEventsTableFilterComposer,
      $$SoireeEventsTableOrderingComposer,
      $$SoireeEventsTableAnnotationComposer,
      $$SoireeEventsTableCreateCompanionBuilder,
      $$SoireeEventsTableUpdateCompanionBuilder,
      (StoredEvent, $$SoireeEventsTableReferences),
      StoredEvent,
      PrefetchHooks Function({bool soireeId})
    >;
typedef $$PlayersTableCreateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  required String name,
  Value<bool> archived,
  Value<bool> hasPlayed,
});
typedef $$PlayersTableUpdateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<bool> archived,
  Value<bool> hasPlayed,
});

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPlayed => $composableBuilder(
    column: $table.hasPlayed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPlayed => $composableBuilder(
    column: $table.hasPlayed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get hasPlayed =>
      $composableBuilder(column: $table.hasPlayed, builder: (column) => column);
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          StoredPlayer,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (
            StoredPlayer,
            BaseReferences<_$AppDatabase, $PlayersTable, StoredPlayer>,
          ),
          StoredPlayer,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<bool> hasPlayed = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                name: name,
                archived: archived,
                hasPlayed: hasPlayed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> archived = const Value.absent(),
                Value<bool> hasPlayed = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                name: name,
                archived: archived,
                hasPlayed: hasPlayed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayersTable, StoredPlayer>(table),
                  BaseReferences<_$AppDatabase, $PlayersTable, StoredPlayer>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      StoredPlayer,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (
        StoredPlayer,
        BaseReferences<_$AppDatabase, $PlayersTable, StoredPlayer>,
      ),
      StoredPlayer,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SoireesTableTableManager get soirees =>
      $$SoireesTableTableManager(_db, _db.soirees);
  $$SoireeEventsTableTableManager get soireeEvents =>
      $$SoireeEventsTableTableManager(_db, _db.soireeEvents);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
}
