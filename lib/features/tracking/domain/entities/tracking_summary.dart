import 'package:equatable/equatable.dart';

class TrackingSummary extends Equatable {
  const TrackingSummary({
    required this.sessionCount,
    required this.totalDistanceMeters,
  });

  final int sessionCount;
  final double totalDistanceMeters;

  @override
  List<Object?> get props => [sessionCount, totalDistanceMeters];
}

class SessionRecordSummary extends Equatable {
  const SessionRecordSummary({
    required this.recordCount,
    required this.pendingCount,
    required this.syncingCount,
    required this.retryCount,
    required this.syncedCount,
    required this.failedCount,
  });

  final int recordCount;
  final int pendingCount;
  final int syncingCount;
  final int retryCount;
  final int syncedCount;
  final int failedCount;

  int get notSyncedCount =>
      pendingCount + syncingCount + retryCount + failedCount;

  @override
  List<Object?> get props => [
    recordCount,
    pendingCount,
    syncingCount,
    retryCount,
    syncedCount,
    failedCount,
  ];
}
