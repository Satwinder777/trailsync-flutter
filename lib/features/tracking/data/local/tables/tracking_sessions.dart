// ignore_for_file: prefer_single_quotes

import 'package:drift/drift.dart';

@TableIndex(name: 'tracking_sessions_started_at_idx', columns: {#startedAt})
@TableIndex(
  name: 'tracking_sessions_owner_started_at_idx',
  columns: {#ownerUserId, #startedAt},
)
@TableIndex(
  name: 'tracking_sessions_status_started_at_idx',
  columns: {#status, #startedAt},
)
class TrackingSessions extends Table {
  TextColumn get id => text().customConstraint(
    "NOT NULL CHECK (length(id) = 36 AND id NOT GLOB '*[^0-9a-fA-F-]*' "
    "AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' "
    "AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-')",
  )();

  TextColumn get ownerUserId => text().nullable().customConstraint(
    "CHECK (owner_user_id IS NULL OR (length(owner_user_id) = 36 "
    "AND owner_user_id NOT GLOB '*[^0-9a-fA-F-]*' "
    "AND substr(owner_user_id, 9, 1) = '-' "
    "AND substr(owner_user_id, 14, 1) = '-' "
    "AND substr(owner_user_id, 19, 1) = '-' "
    "AND substr(owner_user_id, 24, 1) = '-'))",
  )();

  TextColumn get title => text().nullable()();

  TextColumn get status => text().customConstraint(
    "NOT NULL DEFAULT 'recording' "
    "CHECK (status IN ('recording', 'paused', 'completed', 'cancelled'))",
  )();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable().customConstraint(
    'CHECK (ended_at IS NULL OR ended_at >= started_at)',
  )();

  RealColumn get distanceMeters => real().customConstraint(
    'NOT NULL DEFAULT 0 CHECK (distance_meters >= 0)',
  )();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
