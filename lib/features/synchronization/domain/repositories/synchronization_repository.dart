import '../entities/sync_queue_stats.dart';
import '../entities/sync_report.dart';

abstract interface class SynchronizationRepository {
  Future<SyncQueueStats> getQueueStats();

  Future<SyncReport> synchronizePendingRecords();
}
