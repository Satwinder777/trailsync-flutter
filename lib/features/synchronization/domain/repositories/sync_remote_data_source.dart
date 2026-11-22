import '../../../tracking/domain/entities/location_record.dart';
import '../../../tracking/domain/entities/tracking_session.dart';
import '../entities/sync_record_acknowledgement.dart';

abstract interface class SyncRemoteDataSource {
  Future<bool> isBackendReachable();

  /// Ensures the session exists, then uploads its records in one batch.
  Future<List<SyncRecordAcknowledgement>> uploadBatch({
    required TrackingSession session,
    required List<LocationRecord> records,
  });
}
