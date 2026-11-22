import 'package:drift/drift.dart';

import '../../../../app/database/app_database.dart' as db;
import '../../domain/entities/location_record.dart';
import '../../domain/entities/location_record_page.dart';
import '../../domain/entities/position_sample.dart';
import '../../domain/entities/tracking_route_point.dart';
import '../../domain/entities/tracking_session.dart';
import '../../domain/entities/tracking_session_page.dart';
import '../../domain/entities/tracking_summary.dart';
import '../../domain/services/location_sample_filter.dart';

class TrackingLocalDataSource {
  const TrackingLocalDataSource(this._database);

  final db.AppDatabase _database;

  Future<TrackingSession> createSession({
    required String id,
    required DateTime startedAt,
  }) async {
    final startedAtUtc = startedAt.toUtc();
    await _database
        .into(_database.trackingSessions)
        .insert(
          db.TrackingSessionsCompanion.insert(
            id: id,
            status: const Value('recording'),
            startedAt: startedAtUtc,
            distanceMeters: const Value(0),
          ),
        );
    final row = await (_database.select(
      _database.trackingSessions,
    )..where((session) => session.id.equals(id))).getSingle();
    return _mapSession(row);
  }

  Future<TrackingSession?> getActiveSession() async {
    final query = _database.select(_database.trackingSessions)
      ..where((session) => session.status.equals('recording'))
      ..orderBy([(session) => OrderingTerm.desc(session.startedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapSession(row);
  }

  Future<TrackingSessionPage> getSessionsPage({
    required int limit,
    TrackingSessionCursor? before,
  }) async {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100.');
    }
    final query = _database.select(_database.trackingSessions)
      ..where((session) {
        if (before == null) return const Constant(true);
        return session.startedAt.isSmallerThanValue(before.startedAt) |
            (session.startedAt.equals(before.startedAt) &
                session.id.isSmallerThanValue(before.sessionId));
      })
      ..orderBy([
        (session) => OrderingTerm.desc(session.startedAt),
        (session) => OrderingTerm.desc(session.id),
      ])
      ..limit(limit + 1);
    final rows = await query.get();
    final hasMore = rows.length > limit;
    final sessions = rows
        .take(limit)
        .map<TrackingSession>(_mapSession)
        .toList(growable: false);
    final last = sessions.isEmpty ? null : sessions.last;
    return TrackingSessionPage(
      sessions: sessions,
      hasMore: hasMore,
      nextCursor: hasMore && last != null
          ? TrackingSessionCursor(startedAt: last.startedAt, sessionId: last.id)
          : null,
    );
  }

  Future<TrackingSession?> getSession(String sessionId) async {
    final query = _database.select(_database.trackingSessions)
      ..where((session) => session.id.equals(sessionId))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapSession(row);
  }

  Future<TrackingSummary> getTrackingSummary() async {
    final sessionCount = _database.trackingSessions.id.count();
    final countQuery = _database.selectOnly(_database.trackingSessions)
      ..addColumns([sessionCount]);
    final countRow = await countQuery.getSingle();
    final distance = _database.trackingSessions.distanceMeters.sum();
    final distanceQuery = _database.selectOnly(_database.trackingSessions)
      ..addColumns([distance])
      ..where(_database.trackingSessions.status.isNotIn(const ['recording']));
    final distanceRow = await distanceQuery.getSingle();
    return TrackingSummary(
      sessionCount: countRow.read(sessionCount) ?? 0,
      totalDistanceMeters: distanceRow.read(distance) ?? 0,
    );
  }

  Future<SessionRecordSummary> getSessionRecordSummary(String sessionId) async {
    final row = await _database
        .customSelect(
          '''
          SELECT COUNT(*) AS record_count,
                 COALESCE(SUM(sync_status = 'pending'), 0) AS pending_count,
                 COALESCE(SUM(sync_status = 'syncing'), 0) AS syncing_count,
                 COALESCE(SUM(sync_status = 'retry'), 0) AS retry_count,
                 COALESCE(SUM(sync_status = 'synced'), 0) AS synced_count,
                 COALESCE(SUM(sync_status = 'failed'), 0) AS failed_count
          FROM location_records
          WHERE session_id = ?
          ''',
          variables: [Variable.withString(sessionId)],
        )
        .getSingle();
    return SessionRecordSummary(
      recordCount: row.read<int>('record_count'),
      pendingCount: row.read<int>('pending_count'),
      syncingCount: row.read<int>('syncing_count'),
      retryCount: row.read<int>('retry_count'),
      syncedCount: row.read<int>('synced_count'),
      failedCount: row.read<int>('failed_count'),
    );
  }

  Future<List<TrackingRoutePoint>> getRouteOverview({
    required String sessionId,
    required int maxPoints,
  }) async {
    if (maxPoints < 2 || maxPoints > 2000) {
      throw ArgumentError.value(
        maxPoints,
        'maxPoints',
        'Must be between 2 and 2000.',
      );
    }
    final rows = await _database
        .customSelect(
          '''
          WITH ranked_records AS (
            SELECT client_record_id, recorded_at, latitude, longitude,
                   ROW_NUMBER() OVER (
                     ORDER BY recorded_at ASC, client_record_id ASC
                   ) AS sequence_number,
                   COUNT(*) OVER () AS total_count
            FROM location_records
            WHERE session_id = ?
          )
          SELECT client_record_id, recorded_at, latitude, longitude
          FROM ranked_records
          WHERE sequence_number = 1
             OR sequence_number = total_count
             OR ((sequence_number - 1) %
                 MAX(1, CAST((total_count + ? - 3) / (? - 1) AS INTEGER))) = 0
          ORDER BY sequence_number ASC
          ''',
          variables: [
            Variable.withString(sessionId),
            Variable.withInt(maxPoints),
            Variable.withInt(maxPoints),
          ],
        )
        .get();
    return rows
        .map((row) {
          final data = row.data;
          return TrackingRoutePoint(
            recordId: _database.typeMapping.read(
              DriftSqlType.string,
              data['client_record_id'],
            )!,
            recordedAt: _database.typeMapping.read(
              DriftSqlType.dateTime,
              data['recorded_at'],
            )!,
            latitude: _database.typeMapping.read(
              DriftSqlType.double,
              data['latitude'],
            )!,
            longitude: _database.typeMapping.read(
              DriftSqlType.double,
              data['longitude'],
            )!,
          );
        })
        .toList(growable: false);
  }

  Future<LocationRecord?> getLatestRecord(String sessionId) async {
    final query = _database.select(_database.locationRecords)
      ..where((record) => record.sessionId.equals(sessionId))
      ..orderBy([
        (record) => OrderingTerm.desc(record.recordedAt),
        (record) => OrderingTerm.desc(record.clientRecordId),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRecord(row);
  }

  Future<int> countRecords(String sessionId) async {
    final count = _database.locationRecords.clientRecordId.count();
    final query = _database.selectOnly(_database.locationRecords)
      ..addColumns([count])
      ..where(_database.locationRecords.sessionId.equals(sessionId));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<TrackingSession> appendRecord(LocationRecord record) async {
    return _database.transaction(() async {
      final sessionQuery = _database.select(_database.trackingSessions)
        ..where((session) => session.id.equals(record.sessionId));
      final session = await sessionQuery.getSingle();
      if (session.status != 'recording') {
        throw StateError(
          'Location records can only be added to a recording session.',
        );
      }

      final previous = await getLatestRecord(record.sessionId);
      if (previous != null && !record.recordedAt.isAfter(previous.recordedAt)) {
        throw StateError('Location record timestamps must increase.');
      }
      await _database
          .into(_database.locationRecords)
          .insert(
            db.LocationRecordsCompanion.insert(
              clientRecordId: record.clientRecordId,
              sessionId: record.sessionId,
              recordedAt: record.recordedAt.toUtc(),
              latitude: record.latitude,
              longitude: record.longitude,
              altitudeM: Value(record.altitudeM),
              accuracyM: Value(record.accuracyM),
              speedMps: Value(record.speedMps),
              headingDeg: Value(record.headingDeg),
            ),
          );

      var additionalDistance = 0.0;
      if (previous != null) {
        additionalDistance = LocationSampleFilter.distanceMeters(
          PositionSample(
            recordedAt: previous.recordedAt,
            latitude: previous.latitude,
            longitude: previous.longitude,
          ),
          PositionSample(
            recordedAt: record.recordedAt,
            latitude: record.latitude,
            longitude: record.longitude,
          ),
        );
      }

      await (_database.update(
        _database.trackingSessions,
      )..where((row) => row.id.equals(record.sessionId))).write(
        db.TrackingSessionsCompanion(
          distanceMeters: Value(session.distanceMeters + additionalDistance),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      final updated = await sessionQuery.getSingle();
      return _mapSession(updated);
    });
  }

  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
  }) async {
    await (_database.update(
      _database.trackingSessions,
    )..where((session) => session.id.equals(sessionId))).write(
      db.TrackingSessionsCompanion(
        status: const Value('completed'),
        endedAt: Value(endedAt.toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    final query = _database.select(_database.trackingSessions)
      ..where((session) => session.id.equals(sessionId));
    return _mapSession(await query.getSingle());
  }

  Future<LocationRecordPage> getRecordsPage({
    required String sessionId,
    required int limit,
    LocationRecordCursor? after,
  }) async {
    if (limit < 1 || limit > 200) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 200.');
    }

    final query = _database.select(_database.locationRecords)
      ..where((record) {
        final belongsToSession = record.sessionId.equals(sessionId);
        if (after == null) return belongsToSession;
        return belongsToSession &
            (record.recordedAt.isSmallerThanValue(after.recordedAt) |
                (record.recordedAt.equals(after.recordedAt) &
                    record.clientRecordId.isSmallerThanValue(
                      after.clientRecordId,
                    )));
      })
      ..orderBy([
        (record) => OrderingTerm.desc(record.recordedAt),
        (record) => OrderingTerm.desc(record.clientRecordId),
      ])
      ..limit(limit + 1);
    final rows = await query.get();
    final hasMore = rows.length > limit;
    final pageRows = hasMore ? rows.sublist(0, limit) : rows;
    final records = pageRows
        .map<LocationRecord>(_mapRecord)
        .toList(growable: false);
    final last = records.isEmpty ? null : records.last;
    return LocationRecordPage(
      records: records,
      hasMore: hasMore,
      nextCursor: hasMore && last != null
          ? LocationRecordCursor(
              recordedAt: last.recordedAt,
              clientRecordId: last.clientRecordId,
            )
          : null,
    );
  }

  TrackingSession _mapSession(db.TrackingSession row) => TrackingSession(
    id: row.id,
    ownerUserId: row.ownerUserId,
    title: row.title,
    status: TrackingSessionStatus.values.byName(row.status),
    startedAt: row.startedAt.toUtc(),
    endedAt: row.endedAt?.toUtc(),
    distanceMeters: row.distanceMeters,
  );

  LocationRecord _mapRecord(db.LocationRecord row) => LocationRecord(
    clientRecordId: row.clientRecordId,
    sessionId: row.sessionId,
    recordedAt: row.recordedAt.toUtc(),
    latitude: row.latitude,
    longitude: row.longitude,
    altitudeM: row.altitudeM,
    accuracyM: row.accuracyM,
    speedMps: row.speedMps,
    headingDeg: row.headingDeg,
    syncStatus: LocationSyncStatus.values.byName(row.syncStatus),
  );
}
