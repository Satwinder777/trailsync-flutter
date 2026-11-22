import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/app/database/app_database.dart' as storage;
import 'package:trailsync/features/synchronization/data/local/drift_sync_local_store.dart';
import 'package:trailsync/features/synchronization/data/repositories/offline_first_synchronization_repository.dart';
import 'package:trailsync/features/synchronization/domain/entities/sync_record_acknowledgement.dart';
import 'package:trailsync/features/synchronization/domain/entities/sync_report.dart';
import 'package:trailsync/features/synchronization/domain/repositories/sync_remote_data_source.dart';
import 'package:trailsync/features/synchronization/domain/services/exponential_backoff_policy.dart';
import 'package:trailsync/features/synchronization/domain/services/sync_remote_failure.dart';
import 'package:trailsync/features/tracking/data/local/tracking_local_data_source.dart';
import 'package:trailsync/features/tracking/data/repositories/local_tracking_repository.dart';
import 'package:trailsync/features/tracking/domain/entities/location_record.dart';
import 'package:trailsync/features/tracking/domain/entities/tracking_session.dart';
import 'package:trailsync/features/tracking/domain/repositories/tracking_repository.dart';

void main() {
  final now = DateTime.utc(2026, 11, 22, 10);
  late storage.AppDatabase database;
  late LocalTrackingRepository trackingRepository;
  late DriftSyncLocalStore localStore;
  late RecordingRemoteDataSource remote;
  late OfflineFirstSynchronizationRepository synchronizationRepository;
  late TrackingSession session;

  setUp(() async {
    database = storage.AppDatabase.forTesting(NativeDatabase.memory());
    trackingRepository = LocalTrackingRepository(
      dataSource: TrackingLocalDataSource(database),
    );
    localStore = DriftSyncLocalStore(database);
    remote = RecordingRemoteDataSource();
    session = await trackingRepository.createSession(startedAt: now);
    await _insertRecord(
      trackingRepository,
      session.id,
      recordId: '123e4567-e89b-42d3-a456-426614174100',
      seconds: 1,
    );
    synchronizationRepository = _createRepository(
      localStore: localStore,
      remote: remote,
    );
  });

  tearDown(() async => database.close());

  test('keeps local points pending and recovers interrupted claims', () async {
    expect((await localStore.getQueueStats()).pendingCount, 1);
    final firstClaim = await localStore.claimNextBatch(limit: 10, now: now);
    expect(
      firstClaim?.records.single.clientRecordId,
      '123e4567-e89b-42d3-a456-426614174100',
    );

    await localStore.recoverInterruptedRecords();
    expect((await localStore.getQueueStats()).pendingCount, 1);
    final recoveredClaim = await localStore.claimNextBatch(limit: 10, now: now);

    expect(
      recoveredClaim?.records.single.clientRecordId,
      firstClaim?.records.single.clientRecordId,
    );
  });

  test('uploads acknowledged records in configurable batches', () async {
    await _insertRecord(
      trackingRepository,
      session.id,
      recordId: '123e4567-e89b-42d3-a456-426614174101',
      seconds: 2,
    );
    await _insertRecord(
      trackingRepository,
      session.id,
      recordId: '123e4567-e89b-42d3-a456-426614174102',
      seconds: 3,
    );
    synchronizationRepository = _createRepository(
      localStore: localStore,
      remote: remote,
      batchSize: 2,
    );
    remote.onUpload = (batch, records) async =>
        _acknowledgeAll(records, SyncAcknowledgementStatus.accepted);

    final report = await synchronizationRepository.synchronizePendingRecords();

    expect(report.outcome, SyncOutcome.completed);
    expect(report.acceptedCount, 3);
    expect(remote.uploadSizes, [2, 1]);
    expect(report.queue.pendingCount, 0);
    expect(report.queue.syncedCount, 3);
  });

  test('marks records synced only after an accepted acknowledgement', () async {
    remote.onUpload = (batch, records) async =>
        _acknowledgeAll(records, SyncAcknowledgementStatus.accepted);

    final report = await synchronizationRepository.synchronizePendingRecords();

    expect(report.acceptedCount, 1);
    expect(report.queue.pendingCount, 0);
    expect(report.queue.syncedCount, 1);
    expect(remote.uploadedIds.single, '123e4567-e89b-42d3-a456-426614174100');
  });

  test(
    'treats duplicate acknowledgement as successful idempotent sync',
    () async {
      remote.onUpload = (batch, records) async =>
          _acknowledgeAll(records, SyncAcknowledgementStatus.duplicate);

      final report = await synchronizationRepository
          .synchronizePendingRecords();

      expect(report.duplicateCount, 1);
      expect(report.queue.pendingCount, 0);
      expect(report.queue.syncedCount, 1);
    },
  );

  test(
    'timeout preserves the record and schedules an exponential retry',
    () async {
      remote.failure = const SyncRemoteFailure(
        SyncRemoteFailureKind.timeout,
        'request timed out',
      );

      final report = await synchronizationRepository
          .synchronizePendingRecords();

      expect(report.outcome, SyncOutcome.retryScheduled);
      expect(report.queue.pendingCount, 1);
      expect(report.queue.syncedCount, 0);
      expect(await localStore.claimNextBatch(limit: 10, now: now), isNull);
      final retried = await localStore.claimNextBatch(
        limit: 10,
        now: now.add(const Duration(seconds: 5)),
      );
      expect(
        retried?.records.single.clientRecordId,
        '123e4567-e89b-42d3-a456-426614174100',
      );
      expect(retried?.attemptCount, 1);
    },
  );

  test(
    'coalesces concurrent synchronization requests into one operation',
    () async {
      final gate = Completer<List<SyncRecordAcknowledgement>>();
      remote.onUpload = (_, _) => gate.future;

      final first = synchronizationRepository.synchronizePendingRecords();
      final second = synchronizationRepository.synchronizePendingRecords();
      expect(identical(first, second), isTrue);
      await remote.uploadStarted.future.timeout(const Duration(seconds: 2));
      expect(remote.uploadCount, 1);

      gate.complete(
        _acknowledgeAll(
          remote.lastUploadedRecords!,
          SyncAcknowledgementStatus.accepted,
        ),
      );
      final results = await Future.wait([first, second]);
      expect(results.every((result) => result.acceptedCount == 1), isTrue);
      expect(remote.uploadCount, 1);
    },
  );

  test('preserves server-rejected records in the failed queue', () async {
    remote.onUpload = (batch, records) async => [
      SyncRecordAcknowledgement(
        clientRecordId: records.single.clientRecordId,
        status: SyncAcknowledgementStatus.rejected,
        errorCode: 'invalid_coordinate',
      ),
    ];

    final report = await synchronizationRepository.synchronizePendingRecords();

    expect(report.rejectedCount, 1);
    expect(report.queue.pendingCount, 0);
    expect(report.queue.failedCount, 1);
    expect(report.queue.syncedCount, 0);
  });

  test('does not claim records when backend is unreachable', () async {
    remote.reachable = false;

    final report = await synchronizationRepository.synchronizePendingRecords();

    expect(report.outcome, SyncOutcome.retryScheduled);
    expect(remote.uploadCount, 0);
    expect(report.queue.pendingCount, 1);
    expect(report.queue.nextRetryAt, isNotNull);
  });
}

OfflineFirstSynchronizationRepository _createRepository({
  required DriftSyncLocalStore localStore,
  required RecordingRemoteDataSource remote,
  int batchSize = 10,
}) => OfflineFirstSynchronizationRepository(
  localStore: localStore,
  remoteDataSource: remote,
  batchSize: batchSize,
  now: () => DateTime.utc(2026, 11, 22, 10),
  backoffPolicy: ExponentialBackoffPolicy(
    baseDelay: const Duration(seconds: 10),
    maximumDelay: const Duration(minutes: 5),
    randomValue: () => 0,
  ),
);

Future<void> _insertRecord(
  TrackingRepository repository,
  String sessionId, {
  required String recordId,
  required int seconds,
}) async {
  await repository.appendRecord(
    LocationRecord(
      clientRecordId: recordId,
      sessionId: sessionId,
      recordedAt: DateTime.utc(2026, 11, 22, 10, 0, seconds),
      latitude: 37 + seconds / 10000,
      longitude: -122,
      accuracyM: 4,
    ),
  );
}

List<SyncRecordAcknowledgement> _acknowledgeAll(
  List<LocationRecord> records,
  SyncAcknowledgementStatus status,
) => records
    .map(
      (record) => SyncRecordAcknowledgement(
        clientRecordId: record.clientRecordId,
        status: status,
        remoteRecordId: '323e4567-e89b-42d3-a456-426614174100',
      ),
    )
    .toList(growable: false);

class RecordingRemoteDataSource implements SyncRemoteDataSource {
  bool reachable = true;
  int uploadCount = 0;
  Object? failure;
  List<int> uploadSizes = [];
  List<String> uploadedIds = [];
  List<LocationRecord>? lastUploadedRecords;
  Completer<void> uploadStarted = Completer<void>();
  Future<List<SyncRecordAcknowledgement>> Function(
    TrackingSession session,
    List<LocationRecord> records,
  )?
  onUpload;

  @override
  Future<bool> isBackendReachable() async => reachable;

  @override
  Future<List<SyncRecordAcknowledgement>> uploadBatch({
    required TrackingSession session,
    required List<LocationRecord> records,
  }) async {
    uploadCount++;
    uploadSizes = [...uploadSizes, records.length];
    uploadedIds = [
      ...uploadedIds,
      ...records.map((record) => record.clientRecordId),
    ];
    lastUploadedRecords = records;
    if (!uploadStarted.isCompleted) uploadStarted.complete();
    if (failure case final error?) throw error;
    return onUpload?.call(session, records) ??
        _acknowledgeAll(records, SyncAcknowledgementStatus.accepted);
  }
}
