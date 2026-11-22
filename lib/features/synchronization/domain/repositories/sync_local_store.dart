import '../entities/pending_sync_batch.dart';
import '../entities/sync_queue_stats.dart';

abstract interface class SyncLocalStore {
  Future<void> recoverInterruptedRecords();

  Future<SyncQueueStats> getQueueStats();

  /// Atomically claims one bounded, due batch belonging to a single session.
  Future<PendingSyncBatch?> claimNextBatch({
    required int limit,
    required DateTime now,
  });

  Future<void> markSynced({
    required List<String> clientRecordIds,
    required DateTime syncedAt,
  });

  Future<void> scheduleRetry({
    required List<String> clientRecordIds,
    required int attempt,
    required DateTime nextAttemptAt,
    required String error,
  });

  Future<void> returnToPending({
    required List<String> clientRecordIds,
    required String error,
  });

  Future<void> markFailed({
    required List<String> clientRecordIds,
    required String error,
  });
}
