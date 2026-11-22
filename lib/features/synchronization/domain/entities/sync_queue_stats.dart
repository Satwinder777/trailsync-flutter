import 'package:equatable/equatable.dart';

class SyncQueueStats extends Equatable {
  const SyncQueueStats({
    required this.pendingCount,
    required this.failedCount,
    required this.syncedCount,
    this.nextRetryAt,
    this.lastSyncAt,
  });

  final int pendingCount;
  final int failedCount;
  final int syncedCount;
  final DateTime? nextRetryAt;
  final DateTime? lastSyncAt;

  @override
  List<Object?> get props => [
    pendingCount,
    failedCount,
    syncedCount,
    nextRetryAt,
    lastSyncAt,
  ];
}
