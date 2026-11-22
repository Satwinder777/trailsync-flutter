import 'dart:async';

import '../../domain/entities/pending_sync_batch.dart';
import '../../domain/entities/sync_queue_stats.dart';
import '../../domain/entities/sync_record_acknowledgement.dart';
import '../../domain/entities/sync_report.dart';
import '../../domain/repositories/sync_local_store.dart';
import '../../domain/repositories/sync_remote_data_source.dart';
import '../../domain/repositories/synchronization_repository.dart';
import '../../domain/services/exponential_backoff_policy.dart';
import '../../domain/services/sync_remote_failure.dart';

class OfflineFirstSynchronizationRepository
    implements SynchronizationRepository {
  OfflineFirstSynchronizationRepository({
    required SyncLocalStore localStore,
    required SyncRemoteDataSource remoteDataSource,
    required int batchSize,
    ExponentialBackoffPolicy? backoffPolicy,
    DateTime Function()? now,
  }) : _localStore = localStore,
       _remoteDataSource = remoteDataSource,
       _batchSize = batchSize,
       _backoffPolicy = backoffPolicy ?? ExponentialBackoffPolicy(),
       _now = now ?? DateTime.now {
    if (batchSize < 1 || batchSize > 500) {
      throw ArgumentError.value(
        batchSize,
        'batchSize',
        'Must be from 1 to 500.',
      );
    }
  }

  final SyncLocalStore _localStore;
  final SyncRemoteDataSource _remoteDataSource;
  final int _batchSize;
  final ExponentialBackoffPolicy _backoffPolicy;
  final DateTime Function() _now;
  Future<SyncReport>? _activeSynchronization;

  @override
  Future<SyncQueueStats> getQueueStats() => _localStore.getQueueStats();

  @override
  Future<SyncReport> synchronizePendingRecords() {
    final active = _activeSynchronization;
    if (active != null) return active;

    final operation = _synchronize().whenComplete(() {
      _activeSynchronization = null;
    });
    _activeSynchronization = operation;
    return operation;
  }

  Future<SyncReport> _synchronize() async {
    var acceptedCount = 0;
    var duplicateCount = 0;
    var rejectedCount = 0;
    var outcome = SyncOutcome.completed;
    String? message;

    try {
      await _localStore.recoverInterruptedRecords();
      if ((await _localStore.getQueueStats()).pendingCount == 0) {
        return _report(SyncOutcome.completed);
      }
    } catch (_) {
      return _report(
        SyncOutcome.failed,
        message: 'Could not read the local synchronization queue.',
      );
    }

    try {
      if (!await _remoteDataSource.isBackendReachable()) {
        return _scheduleRetryForNextBatch(
          const SyncRemoteFailure(
            SyncRemoteFailureKind.unavailable,
            'The TrailSync backend is not reachable right now.',
          ),
        );
      }
    } on SyncRemoteFailure catch (failure) {
      if (failure.kind == SyncRemoteFailureKind.authentication ||
          failure.kind == SyncRemoteFailureKind.configuration) {
        return _report(_outcomeForFailure(failure), message: failure.message);
      }
      return _scheduleRetryForNextBatch(failure);
    } catch (_) {
      return _scheduleRetryForNextBatch(
        const SyncRemoteFailure(
          SyncRemoteFailureKind.network,
          'Could not verify the TrailSync backend.',
        ),
      );
    }

    while (true) {
      PendingSyncBatch? batch;
      try {
        batch = await _localStore.claimNextBatch(
          limit: _batchSize,
          now: _now().toUtc(),
        );
      } catch (_) {
        outcome = SyncOutcome.failed;
        message = 'Could not read the local synchronization queue.';
        break;
      }
      if (batch == null) break;

      final ids = batch.records.map((record) => record.clientRecordId).toList();
      try {
        final acknowledgements = await _remoteDataSource.uploadBatch(
          session: batch.session,
          records: batch.records,
        );
        _validateAcknowledgements(batch, acknowledgements);

        final acknowledged = <String>[];
        final permanentlyRejected = <String>[];
        for (final acknowledgement in acknowledgements) {
          switch (acknowledgement.status) {
            case SyncAcknowledgementStatus.accepted:
              acceptedCount++;
              acknowledged.add(acknowledgement.clientRecordId);
            case SyncAcknowledgementStatus.duplicate:
              duplicateCount++;
              acknowledged.add(acknowledgement.clientRecordId);
            case SyncAcknowledgementStatus.rejected:
              rejectedCount++;
              permanentlyRejected.add(acknowledgement.clientRecordId);
          }
        }

        await _localStore.markSynced(
          clientRecordIds: acknowledged,
          syncedAt: _now().toUtc(),
        );
        if (permanentlyRejected.isNotEmpty) {
          final reasons = acknowledgements
              .where((ack) => ack.status == SyncAcknowledgementStatus.rejected)
              .map(
                (ack) =>
                    '${ack.clientRecordId}: ${ack.errorCode ?? 'rejected'}',
              )
              .join('; ');
          await _localStore.markFailed(
            clientRecordIds: permanentlyRejected,
            error: reasons,
          );
        }
      } on SyncRemoteFailure catch (failure) {
        if (failure.kind == SyncRemoteFailureKind.authentication ||
            failure.kind == SyncRemoteFailureKind.configuration) {
          await _localStore.returnToPending(
            clientRecordIds: ids,
            error: failure.message,
          );
          outcome = _outcomeForFailure(failure);
          message = failure.message;
          break;
        }

        final attempt = batch.attemptCount + 1;
        final delay = _backoffPolicy.delayForAttempt(attempt);
        await _localStore.scheduleRetry(
          clientRecordIds: ids,
          attempt: attempt,
          nextAttemptAt: _now().toUtc().add(delay),
          error: failure.message,
        );
        outcome = SyncOutcome.retryScheduled;
        message = failure.message;
        break;
      } catch (error) {
        final attempt = batch.attemptCount + 1;
        final delay = _backoffPolicy.delayForAttempt(attempt);
        await _localStore.scheduleRetry(
          clientRecordIds: ids,
          attempt: attempt,
          nextAttemptAt: _now().toUtc().add(delay),
          error: error.runtimeType.toString(),
        );
        outcome = SyncOutcome.retryScheduled;
        message =
            'The server response could not be verified; records are queued to retry.';
        break;
      }
    }

    return _report(
      outcome,
      acceptedCount: acceptedCount,
      duplicateCount: duplicateCount,
      rejectedCount: rejectedCount,
      message: message,
      completedAt: _now().toUtc(),
    );
  }

  Future<SyncReport> _scheduleRetryForNextBatch(
    SyncRemoteFailure failure,
  ) async {
    try {
      final batch = await _localStore.claimNextBatch(
        limit: _batchSize,
        now: _now().toUtc(),
      );
      if (batch == null) {
        return _report(SyncOutcome.retryScheduled, message: failure.message);
      }

      final attempt = batch.attemptCount + 1;
      await _localStore.scheduleRetry(
        clientRecordIds: batch.records
            .map((record) => record.clientRecordId)
            .toList(growable: false),
        attempt: attempt,
        nextAttemptAt: _now().toUtc().add(
          _backoffPolicy.delayForAttempt(attempt),
        ),
        error: failure.message,
      );
      return _report(SyncOutcome.retryScheduled, message: failure.message);
    } catch (_) {
      return _report(
        SyncOutcome.failed,
        message: 'Could not schedule a retry; saved records remain local.',
      );
    }
  }

  void _validateAcknowledgements(
    PendingSyncBatch batch,
    List<SyncRecordAcknowledgement> acknowledgements,
  ) {
    final expected = batch.records
        .map((record) => record.clientRecordId)
        .toSet();
    final actual = acknowledgements
        .map((acknowledgement) => acknowledgement.clientRecordId)
        .toList(growable: false);
    if (actual.length != expected.length ||
        actual.toSet().length != actual.length ||
        !actual.toSet().containsAll(expected)) {
      throw const FormatException(
        'The sync response did not acknowledge every submitted record exactly once.',
      );
    }
  }

  SyncOutcome _outcomeForFailure(SyncRemoteFailure failure) =>
      switch (failure.kind) {
        SyncRemoteFailureKind.configuration => SyncOutcome.notConfigured,
        SyncRemoteFailureKind.authentication =>
          SyncOutcome.authenticationRequired,
        SyncRemoteFailureKind.timeout ||
        SyncRemoteFailureKind.rateLimited ||
        SyncRemoteFailureKind.network ||
        SyncRemoteFailureKind.unavailable ||
        SyncRemoteFailureKind.server => SyncOutcome.backendUnavailable,
      };

  Future<SyncReport> _report(
    SyncOutcome outcome, {
    int acceptedCount = 0,
    int duplicateCount = 0,
    int rejectedCount = 0,
    String? message,
    DateTime? completedAt,
  }) async {
    final queue = await _localStore.getQueueStats();
    final effectiveOutcome =
        outcome == SyncOutcome.completed &&
            queue.pendingCount > 0 &&
            queue.nextRetryAt != null
        ? SyncOutcome.retryScheduled
        : outcome;
    return SyncReport(
      outcome: effectiveOutcome,
      acceptedCount: acceptedCount,
      duplicateCount: duplicateCount,
      rejectedCount: rejectedCount,
      queue: queue,
      message: message,
      completedAt: completedAt,
    );
  }
}
