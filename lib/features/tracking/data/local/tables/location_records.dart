// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';

import 'tracking_sessions.dart';

@TableIndex(
  name: 'location_records_session_recorded_at_idx',
  columns: {#sessionId, #recordedAt, #clientRecordId},
)
@TableIndex(name: 'location_records_recorded_at_idx', columns: {#recordedAt})
@TableIndex(
  name: 'location_records_sync_due_idx',
  columns: {#syncStatus, #nextAttemptAt, #sessionId, #recordedAt},
)
class LocationRecords extends Table {
  // This UUID is also sent as Supabase's client_record_id during later sync.
  TextColumn get clientRecordId => text().customConstraint(
    "NOT NULL CHECK (length(client_record_id) = 36 "
    "AND client_record_id NOT GLOB '*[^0-9a-fA-F-]*' "
    "AND substr(client_record_id, 9, 1) = '-' "
    "AND substr(client_record_id, 14, 1) = '-' "
    "AND substr(client_record_id, 19, 1) = '-' "
    "AND substr(client_record_id, 24, 1) = '-')",
  )();

  TextColumn get sessionId =>
      text().references(TrackingSessions, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get recordedAt => dateTime()();

  RealColumn get latitude => real().customConstraint(
    'NOT NULL CHECK (latitude >= -90 AND latitude <= 90)',
  )();

  RealColumn get longitude => real().customConstraint(
    'NOT NULL CHECK (longitude >= -180 AND longitude <= 180)',
  )();

  RealColumn get altitudeM => real().nullable()();

  RealColumn get accuracyM => real().nullable().customConstraint(
    'CHECK (accuracy_m IS NULL OR accuracy_m >= 0)',
  )();

  RealColumn get speedMps => real().nullable().customConstraint(
    'CHECK (speed_mps IS NULL OR speed_mps >= 0)',
  )();

  RealColumn get headingDeg => real().nullable().customConstraint(
    'CHECK (heading_deg IS NULL OR (heading_deg >= 0 AND heading_deg < 360))',
  )();

  TextColumn get syncStatus => text().customConstraint(
    "NOT NULL DEFAULT 'pending' "
    "CHECK (sync_status IN ('pending', 'syncing', 'retry', 'synced', 'failed'))",
  )();

  IntColumn get syncAttempts => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK (sync_attempts >= 0)',
  )();

  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  TextColumn get lastSyncError => text().nullable()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientRecordId};
}
