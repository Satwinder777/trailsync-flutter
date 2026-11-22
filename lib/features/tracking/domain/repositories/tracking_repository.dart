import '../entities/location_record.dart';
import '../entities/location_record_page.dart';
import '../entities/tracking_route_point.dart';
import '../entities/tracking_session.dart';
import '../entities/tracking_session_page.dart';
import '../entities/tracking_summary.dart';

abstract interface class TrackingRepository {
  Future<TrackingSession> createSession({required DateTime startedAt});

  Future<TrackingSession?> getActiveSession();

  Future<LocationRecord?> getLatestRecord(String sessionId);

  Future<int> countRecords(String sessionId);

  /// Stores the point and updates the session distance in one local transaction.
  Future<TrackingSession> appendRecord(LocationRecord record);

  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
  });

  Future<LocationRecordPage> getRecordsPage({
    required String sessionId,
    required int limit,
    LocationRecordCursor? after,
  });

  Future<TrackingSummary> getTrackingSummary();

  Future<TrackingSessionPage> getSessionsPage({
    required int limit,
    TrackingSessionCursor? before,
  });

  Future<TrackingSession?> getSession(String sessionId);

  Future<SessionRecordSummary> getSessionRecordSummary(String sessionId);

  /// Returns a bounded, evenly sampled route for map rendering.
  Future<List<TrackingRoutePoint>> getRouteOverview({
    required String sessionId,
    int maxPoints = 1200,
  });
}
