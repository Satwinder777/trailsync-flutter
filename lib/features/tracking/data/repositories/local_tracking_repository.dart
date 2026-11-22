import 'package:uuid/uuid.dart';

import '../../domain/entities/location_record.dart';
import '../../domain/entities/location_record_page.dart';
import '../../domain/entities/tracking_route_point.dart';
import '../../domain/entities/tracking_session.dart';
import '../../domain/entities/tracking_session_page.dart';
import '../../domain/entities/tracking_summary.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../local/tracking_local_data_source.dart';

class LocalTrackingRepository implements TrackingRepository {
  LocalTrackingRepository({
    required TrackingLocalDataSource dataSource,
    Uuid? uuid,
  }) : _dataSource = dataSource,
       _uuid = uuid ?? const Uuid();

  final TrackingLocalDataSource _dataSource;
  final Uuid _uuid;

  @override
  Future<TrackingSession> createSession({required DateTime startedAt}) =>
      _dataSource.createSession(id: _uuid.v4(), startedAt: startedAt);

  @override
  Future<TrackingSession?> getActiveSession() => _dataSource.getActiveSession();

  @override
  Future<LocationRecord?> getLatestRecord(String sessionId) =>
      _dataSource.getLatestRecord(sessionId);

  @override
  Future<int> countRecords(String sessionId) =>
      _dataSource.countRecords(sessionId);

  @override
  Future<TrackingSession> appendRecord(LocationRecord record) =>
      _dataSource.appendRecord(record);

  @override
  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
  }) => _dataSource.completeSession(sessionId: sessionId, endedAt: endedAt);

  @override
  Future<LocationRecordPage> getRecordsPage({
    required String sessionId,
    required int limit,
    LocationRecordCursor? after,
  }) => _dataSource.getRecordsPage(
    sessionId: sessionId,
    limit: limit,
    after: after,
  );

  @override
  Future<TrackingSummary> getTrackingSummary() =>
      _dataSource.getTrackingSummary();

  @override
  Future<TrackingSessionPage> getSessionsPage({
    required int limit,
    TrackingSessionCursor? before,
  }) => _dataSource.getSessionsPage(limit: limit, before: before);

  @override
  Future<TrackingSession?> getSession(String sessionId) =>
      _dataSource.getSession(sessionId);

  @override
  Future<SessionRecordSummary> getSessionRecordSummary(String sessionId) =>
      _dataSource.getSessionRecordSummary(sessionId);

  @override
  Future<List<TrackingRoutePoint>> getRouteOverview({
    required String sessionId,
    int maxPoints = 1200,
  }) =>
      _dataSource.getRouteOverview(sessionId: sessionId, maxPoints: maxPoints);
}
