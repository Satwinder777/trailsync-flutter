import 'package:equatable/equatable.dart';

enum SyncStatus {
  checking,
  offline,
  idle,
  syncing,
  completed,
  retryScheduled,
  backendUnavailable,
  notConfigured,
  authenticationRequired,
  failure,
}

class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.checking,
    this.hasNetwork,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.syncedCount = 0,
    this.acceptedThisRun = 0,
    this.duplicatesThisRun = 0,
    this.lastSyncAt,
    this.nextRetryAt,
    this.message,
  });

  final SyncStatus status;
  final bool? hasNetwork;
  final int pendingCount;
  final int failedCount;
  final int syncedCount;
  final int acceptedThisRun;
  final int duplicatesThisRun;
  final DateTime? lastSyncAt;
  final DateTime? nextRetryAt;
  final String? message;

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    bool? hasNetwork,
    int? pendingCount,
    int? failedCount,
    int? syncedCount,
    int? acceptedThisRun,
    int? duplicatesThisRun,
    DateTime? lastSyncAt,
    DateTime? nextRetryAt,
    String? message,
    bool clearMessage = false,
    bool clearNextRetryAt = false,
  }) => SyncState(
    status: status ?? this.status,
    hasNetwork: hasNetwork ?? this.hasNetwork,
    pendingCount: pendingCount ?? this.pendingCount,
    failedCount: failedCount ?? this.failedCount,
    syncedCount: syncedCount ?? this.syncedCount,
    acceptedThisRun: acceptedThisRun ?? this.acceptedThisRun,
    duplicatesThisRun: duplicatesThisRun ?? this.duplicatesThisRun,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    nextRetryAt: clearNextRetryAt ? null : nextRetryAt ?? this.nextRetryAt,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    status,
    hasNetwork,
    pendingCount,
    failedCount,
    syncedCount,
    acceptedThisRun,
    duplicatesThisRun,
    lastSyncAt,
    nextRetryAt,
    message,
  ];
}
