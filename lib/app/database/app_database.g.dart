// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TrackingSessionsTable extends TrackingSessions
    with TableInfo<$TrackingSessionsTable, TrackingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(id) = 36 AND id NOT GLOB \'*[^0-9a-fA-F-]*\' AND substr(id, 9, 1) = \'-\' AND substr(id, 14, 1) = \'-\' AND substr(id, 19, 1) = \'-\' AND substr(id, 24, 1) = \'-\')',
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (owner_user_id IS NULL OR (length(owner_user_id) = 36 AND owner_user_id NOT GLOB \'*[^0-9a-fA-F-]*\' AND substr(owner_user_id, 9, 1) = \'-\' AND substr(owner_user_id, 14, 1) = \'-\' AND substr(owner_user_id, 19, 1) = \'-\' AND substr(owner_user_id, 24, 1) = \'-\'))',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'recording\' CHECK (status IN (\'recording\', \'paused\', \'completed\', \'cancelled\'))',
    defaultValue: const CustomExpression('\'recording\''),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (ended_at IS NULL OR ended_at >= started_at)',
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (distance_meters >= 0)',
    defaultValue: const CustomExpression('0'),
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
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUserId,
    title,
    status,
    startedAt,
    endedAt,
    distanceMeters,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TrackingSessionsTable createAlias(String alias) {
    return $TrackingSessionsTable(attachedDatabase, alias);
  }
}

class TrackingSession extends DataClass implements Insertable<TrackingSession> {
  final String id;
  final String? ownerUserId;
  final String? title;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceMeters;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TrackingSession({
    required this.id,
    this.ownerUserId,
    this.title,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.distanceMeters,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TrackingSessionsCompanion toCompanion(bool nullToAbsent) {
    return TrackingSessionsCompanion(
      id: Value(id),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      distanceMeters: Value(distanceMeters),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TrackingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingSession(
      id: serializer.fromJson<String>(json['id']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      title: serializer.fromJson<String?>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'title': serializer.toJson<String?>(title),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TrackingSession copyWith({
    String? id,
    Value<String?> ownerUserId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    String? status,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    double? distanceMeters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TrackingSession(
    id: id ?? this.id,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    title: title.present ? title.value : this.title,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TrackingSession copyWithCompanion(TrackingSessionsCompanion data) {
    return TrackingSession(
      id: data.id.present ? data.id.value : this.id,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingSession(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUserId,
    title,
    status,
    startedAt,
    endedAt,
    distanceMeters,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingSession &&
          other.id == this.id &&
          other.ownerUserId == this.ownerUserId &&
          other.title == this.title &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distanceMeters == this.distanceMeters &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TrackingSessionsCompanion extends UpdateCompanion<TrackingSession> {
  final Value<String> id;
  final Value<String?> ownerUserId;
  final Value<String?> title;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> distanceMeters;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TrackingSessionsCompanion({
    this.id = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackingSessionsCompanion.insert({
    required String id,
    this.ownerUserId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt);
  static Insertable<TrackingSession> custom({
    Expression<String>? id,
    Expression<String>? ownerUserId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? distanceMeters,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerUserId,
    Value<String?>? title,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double>? distanceMeters,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TrackingSessionsCompanion(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      title: title ?? this.title,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocationRecordsTable extends LocationRecords
    with TableInfo<$LocationRecordsTable, LocationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientRecordIdMeta = const VerificationMeta(
    'clientRecordId',
  );
  @override
  late final GeneratedColumn<String> clientRecordId = GeneratedColumn<String>(
    'client_record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(client_record_id) = 36 AND client_record_id NOT GLOB \'*[^0-9a-fA-F-]*\' AND substr(client_record_id, 9, 1) = \'-\' AND substr(client_record_id, 14, 1) = \'-\' AND substr(client_record_id, 19, 1) = \'-\' AND substr(client_record_id, 24, 1) = \'-\')',
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracking_sessions (id) ON DELETE CASCADE',
    ),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (latitude >= -90 AND latitude <= 90)',
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (longitude >= -180 AND longitude <= 180)',
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (accuracy_m IS NULL OR accuracy_m >= 0)',
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (speed_mps IS NULL OR speed_mps >= 0)',
  );
  static const VerificationMeta _headingDegMeta = const VerificationMeta(
    'headingDeg',
  );
  @override
  late final GeneratedColumn<double> headingDeg = GeneratedColumn<double>(
    'heading_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (heading_deg IS NULL OR (heading_deg >= 0 AND heading_deg < 360))',
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'pending\' CHECK (sync_status IN (\'pending\', \'syncing\', \'retry\', \'synced\', \'failed\'))',
    defaultValue: const CustomExpression('\'pending\''),
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (sync_attempts >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientRecordId,
    sessionId,
    recordedAt,
    latitude,
    longitude,
    altitudeM,
    accuracyM,
    speedMps,
    headingDeg,
    syncStatus,
    syncAttempts,
    nextAttemptAt,
    lastSyncError,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_record_id')) {
      context.handle(
        _clientRecordIdMeta,
        clientRecordId.isAcceptableOrUnknown(
          data['client_record_id']!,
          _clientRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRecordIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('heading_deg')) {
      context.handle(
        _headingDegMeta,
        headingDeg.isAcceptableOrUnknown(data['heading_deg']!, _headingDegMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientRecordId};
  @override
  LocationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationRecord(
      clientRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_record_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      ),
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      headingDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading_deg'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $LocationRecordsTable createAlias(String alias) {
    return $LocationRecordsTable(attachedDatabase, alias);
  }
}

class LocationRecord extends DataClass implements Insertable<LocationRecord> {
  final String clientRecordId;
  final String sessionId;
  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double? altitudeM;
  final double? accuracyM;
  final double? speedMps;
  final double? headingDeg;
  final String syncStatus;
  final int syncAttempts;
  final DateTime? nextAttemptAt;
  final String? lastSyncError;
  final DateTime? syncedAt;
  const LocationRecord({
    required this.clientRecordId,
    required this.sessionId,
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    this.altitudeM,
    this.accuracyM,
    this.speedMps,
    this.headingDeg,
    required this.syncStatus,
    required this.syncAttempts,
    this.nextAttemptAt,
    this.lastSyncError,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_record_id'] = Variable<String>(clientRecordId);
    map['session_id'] = Variable<String>(sessionId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || altitudeM != null) {
      map['altitude_m'] = Variable<double>(altitudeM);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    if (!nullToAbsent || headingDeg != null) {
      map['heading_deg'] = Variable<double>(headingDeg);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocationRecordsCompanion toCompanion(bool nullToAbsent) {
    return LocationRecordsCompanion(
      clientRecordId: Value(clientRecordId),
      sessionId: Value(sessionId),
      recordedAt: Value(recordedAt),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitudeM: altitudeM == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeM),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      headingDeg: headingDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(headingDeg),
      syncStatus: Value(syncStatus),
      syncAttempts: Value(syncAttempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationRecord(
      clientRecordId: serializer.fromJson<String>(json['clientRecordId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitudeM: serializer.fromJson<double?>(json['altitudeM']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      headingDeg: serializer.fromJson<double?>(json['headingDeg']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientRecordId': serializer.toJson<String>(clientRecordId),
      'sessionId': serializer.toJson<String>(sessionId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitudeM': serializer.toJson<double?>(altitudeM),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'speedMps': serializer.toJson<double?>(speedMps),
      'headingDeg': serializer.toJson<double?>(headingDeg),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocationRecord copyWith({
    String? clientRecordId,
    String? sessionId,
    DateTime? recordedAt,
    double? latitude,
    double? longitude,
    Value<double?> altitudeM = const Value.absent(),
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
    Value<double?> headingDeg = const Value.absent(),
    String? syncStatus,
    int? syncAttempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => LocationRecord(
    clientRecordId: clientRecordId ?? this.clientRecordId,
    sessionId: sessionId ?? this.sessionId,
    recordedAt: recordedAt ?? this.recordedAt,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitudeM: altitudeM.present ? altitudeM.value : this.altitudeM,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    headingDeg: headingDeg.present ? headingDeg.value : this.headingDeg,
    syncStatus: syncStatus ?? this.syncStatus,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LocationRecord copyWithCompanion(LocationRecordsCompanion data) {
    return LocationRecord(
      clientRecordId: data.clientRecordId.present
          ? data.clientRecordId.value
          : this.clientRecordId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      headingDeg: data.headingDeg.present
          ? data.headingDeg.value
          : this.headingDeg,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationRecord(')
          ..write('clientRecordId: $clientRecordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('headingDeg: $headingDeg, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientRecordId,
    sessionId,
    recordedAt,
    latitude,
    longitude,
    altitudeM,
    accuracyM,
    speedMps,
    headingDeg,
    syncStatus,
    syncAttempts,
    nextAttemptAt,
    lastSyncError,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationRecord &&
          other.clientRecordId == this.clientRecordId &&
          other.sessionId == this.sessionId &&
          other.recordedAt == this.recordedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitudeM == this.altitudeM &&
          other.accuracyM == this.accuracyM &&
          other.speedMps == this.speedMps &&
          other.headingDeg == this.headingDeg &&
          other.syncStatus == this.syncStatus &&
          other.syncAttempts == this.syncAttempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastSyncError == this.lastSyncError &&
          other.syncedAt == this.syncedAt);
}

class LocationRecordsCompanion extends UpdateCompanion<LocationRecord> {
  final Value<String> clientRecordId;
  final Value<String> sessionId;
  final Value<DateTime> recordedAt;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> altitudeM;
  final Value<double?> accuracyM;
  final Value<double?> speedMps;
  final Value<double?> headingDeg;
  final Value<String> syncStatus;
  final Value<int> syncAttempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastSyncError;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocationRecordsCompanion({
    this.clientRecordId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.headingDeg = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationRecordsCompanion.insert({
    required String clientRecordId,
    required String sessionId,
    required DateTime recordedAt,
    required double latitude,
    required double longitude,
    this.altitudeM = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.headingDeg = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientRecordId = Value(clientRecordId),
       sessionId = Value(sessionId),
       recordedAt = Value(recordedAt),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<LocationRecord> custom({
    Expression<String>? clientRecordId,
    Expression<String>? sessionId,
    Expression<DateTime>? recordedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitudeM,
    Expression<double>? accuracyM,
    Expression<double>? speedMps,
    Expression<double>? headingDeg,
    Expression<String>? syncStatus,
    Expression<int>? syncAttempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastSyncError,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientRecordId != null) 'client_record_id': clientRecordId,
      if (sessionId != null) 'session_id': sessionId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (headingDeg != null) 'heading_deg': headingDeg,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationRecordsCompanion copyWith({
    Value<String>? clientRecordId,
    Value<String>? sessionId,
    Value<DateTime>? recordedAt,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? altitudeM,
    Value<double?>? accuracyM,
    Value<double?>? speedMps,
    Value<double?>? headingDeg,
    Value<String>? syncStatus,
    Value<int>? syncAttempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastSyncError,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LocationRecordsCompanion(
      clientRecordId: clientRecordId ?? this.clientRecordId,
      sessionId: sessionId ?? this.sessionId,
      recordedAt: recordedAt ?? this.recordedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitudeM: altitudeM ?? this.altitudeM,
      accuracyM: accuracyM ?? this.accuracyM,
      speedMps: speedMps ?? this.speedMps,
      headingDeg: headingDeg ?? this.headingDeg,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientRecordId.present) {
      map['client_record_id'] = Variable<String>(clientRecordId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (headingDeg.present) {
      map['heading_deg'] = Variable<double>(headingDeg.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationRecordsCompanion(')
          ..write('clientRecordId: $clientRecordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('headingDeg: $headingDeg, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrackingSessionsTable trackingSessions = $TrackingSessionsTable(
    this,
  );
  late final $LocationRecordsTable locationRecords = $LocationRecordsTable(
    this,
  );
  late final Index trackingSessionsStartedAtIdx = Index(
    'tracking_sessions_started_at_idx',
    'CREATE INDEX tracking_sessions_started_at_idx ON tracking_sessions (started_at)',
  );
  late final Index trackingSessionsOwnerStartedAtIdx = Index(
    'tracking_sessions_owner_started_at_idx',
    'CREATE INDEX tracking_sessions_owner_started_at_idx ON tracking_sessions (owner_user_id, started_at)',
  );
  late final Index trackingSessionsStatusStartedAtIdx = Index(
    'tracking_sessions_status_started_at_idx',
    'CREATE INDEX tracking_sessions_status_started_at_idx ON tracking_sessions (status, started_at)',
  );
  late final Index locationRecordsSessionRecordedAtIdx = Index(
    'location_records_session_recorded_at_idx',
    'CREATE INDEX location_records_session_recorded_at_idx ON location_records (session_id, recorded_at, client_record_id)',
  );
  late final Index locationRecordsRecordedAtIdx = Index(
    'location_records_recorded_at_idx',
    'CREATE INDEX location_records_recorded_at_idx ON location_records (recorded_at)',
  );
  late final Index locationRecordsSyncDueIdx = Index(
    'location_records_sync_due_idx',
    'CREATE INDEX location_records_sync_due_idx ON location_records (sync_status, next_attempt_at, session_id, recorded_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trackingSessions,
    locationRecords,
    trackingSessionsStartedAtIdx,
    trackingSessionsOwnerStartedAtIdx,
    trackingSessionsStatusStartedAtIdx,
    locationRecordsSessionRecordedAtIdx,
    locationRecordsRecordedAtIdx,
    locationRecordsSyncDueIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracking_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('location_records', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TrackingSessionsTableCreateCompanionBuilder =
    TrackingSessionsCompanion Function({
      required String id,
      Value<String?> ownerUserId,
      Value<String?> title,
      Value<String> status,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<double> distanceMeters,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TrackingSessionsTableUpdateCompanionBuilder =
    TrackingSessionsCompanion Function({
      Value<String> id,
      Value<String?> ownerUserId,
      Value<String?> title,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<double> distanceMeters,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TrackingSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TrackingSessionsTable, TrackingSession> {
  $$TrackingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LocationRecordsTable, List<LocationRecord>>
  _locationRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.locationRecords,
    aliasName: $_aliasNameGenerator(
      db.trackingSessions.id,
      db.locationRecords.sessionId,
    ),
  );

  $$LocationRecordsTableProcessedTableManager get locationRecordsRefs {
    final manager = $$LocationRecordsTableTableManager(
      $_db,
      $_db.locationRecords,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _locationRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TrackingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingSessionsTable> {
  $$TrackingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> locationRecordsRefs(
    Expression<bool> Function($$LocationRecordsTableFilterComposer f) f,
  ) {
    final $$LocationRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.locationRecords,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationRecordsTableFilterComposer(
            $db: $db,
            $table: $db.locationRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrackingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingSessionsTable> {
  $$TrackingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingSessionsTable> {
  $$TrackingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> locationRecordsRefs<T extends Object>(
    Expression<T> Function($$LocationRecordsTableAnnotationComposer a) f,
  ) {
    final $$LocationRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.locationRecords,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.locationRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TrackingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackingSessionsTable,
          TrackingSession,
          $$TrackingSessionsTableFilterComposer,
          $$TrackingSessionsTableOrderingComposer,
          $$TrackingSessionsTableAnnotationComposer,
          $$TrackingSessionsTableCreateCompanionBuilder,
          $$TrackingSessionsTableUpdateCompanionBuilder,
          (TrackingSession, $$TrackingSessionsTableReferences),
          TrackingSession,
          PrefetchHooks Function({bool locationRecordsRefs})
        > {
  $$TrackingSessionsTableTableManager(
    _$AppDatabase db,
    $TrackingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingSessionsCompanion(
                id: id,
                ownerUserId: ownerUserId,
                title: title,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceMeters: distanceMeters,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerUserId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackingSessionsCompanion.insert(
                id: id,
                ownerUserId: ownerUserId,
                title: title,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                distanceMeters: distanceMeters,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({locationRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (locationRecordsRefs) db.locationRecords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (locationRecordsRefs)
                    await $_getPrefetchedData<
                      TrackingSession,
                      $TrackingSessionsTable,
                      LocationRecord
                    >(
                      currentTable: table,
                      referencedTable: $$TrackingSessionsTableReferences
                          ._locationRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TrackingSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).locationRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TrackingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackingSessionsTable,
      TrackingSession,
      $$TrackingSessionsTableFilterComposer,
      $$TrackingSessionsTableOrderingComposer,
      $$TrackingSessionsTableAnnotationComposer,
      $$TrackingSessionsTableCreateCompanionBuilder,
      $$TrackingSessionsTableUpdateCompanionBuilder,
      (TrackingSession, $$TrackingSessionsTableReferences),
      TrackingSession,
      PrefetchHooks Function({bool locationRecordsRefs})
    >;
typedef $$LocationRecordsTableCreateCompanionBuilder =
    LocationRecordsCompanion Function({
      required String clientRecordId,
      required String sessionId,
      required DateTime recordedAt,
      required double latitude,
      required double longitude,
      Value<double?> altitudeM,
      Value<double?> accuracyM,
      Value<double?> speedMps,
      Value<double?> headingDeg,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastSyncError,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$LocationRecordsTableUpdateCompanionBuilder =
    LocationRecordsCompanion Function({
      Value<String> clientRecordId,
      Value<String> sessionId,
      Value<DateTime> recordedAt,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> altitudeM,
      Value<double?> accuracyM,
      Value<double?> speedMps,
      Value<double?> headingDeg,
      Value<String> syncStatus,
      Value<int> syncAttempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastSyncError,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

final class $$LocationRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $LocationRecordsTable, LocationRecord> {
  $$LocationRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TrackingSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.trackingSessions.createAlias(
        $_aliasNameGenerator(
          db.locationRecords.sessionId,
          db.trackingSessions.id,
        ),
      );

  $$TrackingSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$TrackingSessionsTableTableManager(
      $_db,
      $_db.trackingSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocationRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LocationRecordsTable> {
  $$LocationRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientRecordId => $composableBuilder(
    column: $table.clientRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get headingDeg => $composableBuilder(
    column: $table.headingDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TrackingSessionsTableFilterComposer get sessionId {
    final $$TrackingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trackingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.trackingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationRecordsTable> {
  $$LocationRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientRecordId => $composableBuilder(
    column: $table.clientRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get headingDeg => $composableBuilder(
    column: $table.headingDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TrackingSessionsTableOrderingComposer get sessionId {
    final $$TrackingSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trackingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.trackingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationRecordsTable> {
  $$LocationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientRecordId => $composableBuilder(
    column: $table.clientRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get headingDeg => $composableBuilder(
    column: $table.headingDeg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$TrackingSessionsTableAnnotationComposer get sessionId {
    final $$TrackingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.trackingSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationRecordsTable,
          LocationRecord,
          $$LocationRecordsTableFilterComposer,
          $$LocationRecordsTableOrderingComposer,
          $$LocationRecordsTableAnnotationComposer,
          $$LocationRecordsTableCreateCompanionBuilder,
          $$LocationRecordsTableUpdateCompanionBuilder,
          (LocationRecord, $$LocationRecordsTableReferences),
          LocationRecord,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LocationRecordsTableTableManager(
    _$AppDatabase db,
    $LocationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientRecordId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> headingDeg = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocationRecordsCompanion(
                clientRecordId: clientRecordId,
                sessionId: sessionId,
                recordedAt: recordedAt,
                latitude: latitude,
                longitude: longitude,
                altitudeM: altitudeM,
                accuracyM: accuracyM,
                speedMps: speedMps,
                headingDeg: headingDeg,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                nextAttemptAt: nextAttemptAt,
                lastSyncError: lastSyncError,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientRecordId,
                required String sessionId,
                required DateTime recordedAt,
                required double latitude,
                required double longitude,
                Value<double?> altitudeM = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> headingDeg = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocationRecordsCompanion.insert(
                clientRecordId: clientRecordId,
                sessionId: sessionId,
                recordedAt: recordedAt,
                latitude: latitude,
                longitude: longitude,
                altitudeM: altitudeM,
                accuracyM: accuracyM,
                speedMps: speedMps,
                headingDeg: headingDeg,
                syncStatus: syncStatus,
                syncAttempts: syncAttempts,
                nextAttemptAt: nextAttemptAt,
                lastSyncError: lastSyncError,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocationRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$LocationRecordsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$LocationRecordsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$LocationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationRecordsTable,
      LocationRecord,
      $$LocationRecordsTableFilterComposer,
      $$LocationRecordsTableOrderingComposer,
      $$LocationRecordsTableAnnotationComposer,
      $$LocationRecordsTableCreateCompanionBuilder,
      $$LocationRecordsTableUpdateCompanionBuilder,
      (LocationRecord, $$LocationRecordsTableReferences),
      LocationRecord,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrackingSessionsTableTableManager get trackingSessions =>
      $$TrackingSessionsTableTableManager(_db, _db.trackingSessions);
  $$LocationRecordsTableTableManager get locationRecords =>
      $$LocationRecordsTableTableManager(_db, _db.locationRecords);
}
