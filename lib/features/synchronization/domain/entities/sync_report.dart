import 'package:equatable/equatable.dart';

import 'sync_queue_stats.dart';

enum SyncOutcome {
  completed,
  backendUnavailable,
  notConfigured,
  authenticationRequired,
  retryScheduled,
  failed,
}

class SyncReport extends Equatable {
  const SyncReport({
    required this.outcome,
    required this.queue,
    this.acceptedCount = 0,
    this.duplicateCount = 0,
    this.rejectedCount = 0,
    this.message,
    this.completedAt,
  });

  final SyncOutcome outcome;
  final SyncQueueStats queue;
  final int acceptedCount;
  final int duplicateCount;
  final int rejectedCount;
  final String? message;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
    outcome,
    queue,
    acceptedCount,
    duplicateCount,
    rejectedCount,
    message,
    completedAt,
  ];
}
