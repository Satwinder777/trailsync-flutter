import 'package:drift/drift.dart';

import '../../../../app/database/app_database.dart' as db;
import '../../../tracking/domain/entities/location_record.dart';
import '../../../tracking/domain/entities/tracking_session.dart';
import '../../domain/entities/pending_sync_batch.dart';
import '../../domain/entities/sync_queue_stats.dart';
import '../../domain/repositories/sync_local_store.dart';

class DriftSyncLocalStore implements SyncLocalStore {
  const DriftSyncLocalStore(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> recoverInterruptedRecords() async {
    await (_database.update(_database.locationRecords)
          ..where((record) => record.syncStatus.equals('syncing')))
        .write(const db.LocationRecordsCompanion(syncStatus: Value('pending')));
  }

  @override
  Future<SyncQueueStats> getQueueStats() async => SyncQueueStats(
    pendingCount: await _countFor({'pending', 'retry', 'syncing'}),
    failedCount: await _countFor({'failed'}),
    syncedCount: await _countFor({'synced'}),
    nextRetryAt: await _nextRetryAt(),
    lastSyncAt: await _lastSyncAt(),
  );

  Future<DateTime?> _lastSyncAt() async {
    final lastSync = _database.locationRecords.syncedAt.max();
    final query = _database.selectOnly(_database.locationRecords)
      ..addColumns([lastSync])
      ..where(_database.locationRecords.syncStatus.equals('synced'));
    return (await query.getSingle()).read(lastSync)?.toUtc();
  }

  Future<DateTime?> _nextRetryAt() async {
    final query = _database.selectOnly(_database.locationRecords)
      ..addColumns([_database.locationRecords.nextAttemptAt])
      ..where(
        _database.locationRecords.syncStatus.equals('retry') &
            _database.locationRecords.nextAttemptAt.isNotNull(),
      )
      ..orderBy([OrderingTerm.asc(_database.locationRecords.nextAttemptAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.read(_database.locationRecords.nextAttemptAt)?.toUtc();
  }

  Future<int> _countFor(Set<String> statuses) async {
    final count = _database.locationRecords.clientRecordId.count();
    final query = _database.selectOnly(_database.locationRecords)
      ..addColumns([count])
      ..where(_database.locationRecords.syncStatus.isIn(statuses.toList()));
    return (await query.getSingle()).read(count) ?? 0;
  }

  @override
  Future<PendingSyncBatch?> claimNextBatch({
    required int limit,
    required DateTime now,
  }) async {
    if (limit < 1 || limit > 500) {
      throw ArgumentError.value(limit, 'limit', 'Must be from 1 to 500.');
    }
    final nowUtc = now.toUtc();
    return _database.transaction(() async {
      final next = _database.select(_database.locationRecords)
        ..where((record) => _isDue(record, nowUtc))
        ..orderBy([
          (record) => OrderingTerm.asc(record.recordedAt),
          (record) => OrderingTerm.asc(record.clientRecordId),
        ])
        ..limit(1);
      final first = await next.getSingleOrNull();
      if (first == null) return null;

      final batchQuery = _database.select(_database.locationRecords)
        ..where(
          (record) =>
              record.sessionId.equals(first.sessionId) & _isDue(record, nowUtc),
        )
        ..orderBy([
          (record) => OrderingTerm.asc(record.recordedAt),
          (record) => OrderingTerm.asc(record.clientRecordId),
        ])
        ..limit(limit);
      final rows = await batchQuery.get();
      if (rows.isEmpty) return null;

      final ids = rows.map((row) => row.clientRecordId).toList(growable: false);
      await (_database.update(_database.locationRecords)..where(
            (record) =>
                record.clientRecordId.isIn(ids) &
                record.syncStatus.isIn(const ['pending', 'retry']),
          ))
          .write(
            const db.LocationRecordsCompanion(syncStatus: Value('syncing')),
          );

      final sessionQuery = _database.select(_database.trackingSessions)
        ..where((session) => session.id.equals(first.sessionId));
      final session = _mapSession(await sessionQuery.getSingle());
      return PendingSyncBatch(
        session: session,
        records: rows.map(_mapRecord).toList(growable: false),
        attemptCount: rows.fold<int>(
          0,
          (maximum, row) =>
              row.syncAttempts > maximum ? row.syncAttempts : maximum,
        ),
      );
    });
  }

  Expression<bool> _isDue(db.$LocationRecordsTable record, DateTime now) =>
      record.syncStatus.isIn(const ['pending', 'retry']) &
      (record.nextAttemptAt.isNull() |
          record.nextAttemptAt.isSmallerOrEqualValue(now));

  @override
  Future<void> markSynced({
    required List<String> clientRecordIds,
    required DateTime syncedAt,
  }) async {
    if (clientRecordIds.isEmpty) return;
    await (_database.update(_database.locationRecords)..where(
          (record) =>
              record.clientRecordId.isIn(clientRecordIds) &
              record.syncStatus.equals('syncing'),
        ))
        .write(
          db.LocationRecordsCompanion(
            syncStatus: const Value('synced'),
            syncedAt: Value(syncedAt.toUtc()),
            nextAttemptAt: const Value(null),
            lastSyncError: const Value(null),
          ),
        );
  }

  @override
  Future<void> scheduleRetry({
    required List<String> clientRecordIds,
    required int attempt,
    required DateTime nextAttemptAt,
    required String error,
  }) async {
    if (clientRecordIds.isEmpty) return;
    await (_database.update(_database.locationRecords)..where(
          (record) =>
              record.clientRecordId.isIn(clientRecordIds) &
              record.syncStatus.equals('syncing'),
        ))
        .write(
          db.LocationRecordsCompanion(
            syncStatus: const Value('retry'),
            syncAttempts: Value(attempt),
            nextAttemptAt: Value(nextAttemptAt.toUtc()),
            lastSyncError: Value(error),
          ),
        );
  }

  @override
  Future<void> returnToPending({
    required List<String> clientRecordIds,
    required String error,
  }) async {
    if (clientRecordIds.isEmpty) return;
    await (_database.update(_database.locationRecords)..where(
          (record) =>
              record.clientRecordId.isIn(clientRecordIds) &
              record.syncStatus.equals('syncing'),
        ))
        .write(
          db.LocationRecordsCompanion(
            syncStatus: const Value('pending'),
            nextAttemptAt: const Value(null),
            lastSyncError: Value(error),
          ),
        );
  }

  @override
  Future<void> markFailed({
    required List<String> clientRecordIds,
    required String error,
  }) async {
    if (clientRecordIds.isEmpty) return;
    await (_database.update(_database.locationRecords)..where(
          (record) =>
              record.clientRecordId.isIn(clientRecordIds) &
              record.syncStatus.equals('syncing'),
        ))
        .write(
          db.LocationRecordsCompanion(
            syncStatus: const Value('failed'),
            nextAttemptAt: const Value(null),
            lastSyncError: Value(error),
          ),
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
