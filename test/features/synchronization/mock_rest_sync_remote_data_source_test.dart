import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/features/synchronization/data/remote/mock_rest_sync_remote_data_source.dart';
import 'package:trailsync/features/synchronization/domain/entities/sync_record_acknowledgement.dart';
import 'package:trailsync/features/tracking/domain/entities/location_record.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_session.dart';

void main() {
  late MockRestSyncRemoteDataSource remote;
  late TrackingSession session;
  late LocationRecord record;

  setUp(() {
    remote = MockRestSyncRemoteDataSource();
    session = TrackingSession(
      id: 'session-001',
      startedAt: DateTime.utc(2026, 11, 22),
      status: TrackingSessionStatus.completed,
      distanceMeters: 1200,
    );
    record = LocationRecord(
      clientRecordId: 'record-001',
      sessionId: session.id,
      recordedAt: DateTime.utc(2026, 11, 22, 9),
      latitude: 37.3,
      longitude: -122,
    );
  });
  tearDown(() => remote.close());

  test(
    'mock REST health endpoint is reachable without external services',
    () async {
      expect(await remote.isBackendReachable(), isTrue);
    },
  );

  test(
    'accepts a stable record ID once and acknowledges a retry as duplicate',
    () async {
      final first = await remote.uploadBatch(
        session: session,
        records: [record],
      );
      final retry = await remote.uploadBatch(
        session: session,
        records: [record],
      );

      expect(first.single.clientRecordId, record.clientRecordId);
      expect(first.single.status, SyncAcknowledgementStatus.accepted);
      expect(retry.single.clientRecordId, record.clientRecordId);
      expect(retry.single.status, SyncAcknowledgementStatus.duplicate);
    },
  );

  test('rejects coordinates outside geographic bounds per record', () async {
    final invalidRecord = LocationRecord(
      clientRecordId: 'record-invalid',
      sessionId: session.id,
      recordedAt: DateTime.utc(2026, 11, 22, 9),
      latitude: 91,
      longitude: -122,
    );

    final acknowledgements = await remote.uploadBatch(
      session: session,
      records: [invalidRecord],
    );

    expect(acknowledgements.single.status, SyncAcknowledgementStatus.rejected);
    expect(acknowledgements.single.errorCode, 'invalid_location');
  });
}
