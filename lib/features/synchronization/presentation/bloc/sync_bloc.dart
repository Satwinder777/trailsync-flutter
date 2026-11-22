import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/sync_report.dart';
import '../../domain/repositories/synchronization_repository.dart';
import '../../domain/services/sync_connectivity_monitor.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> with WidgetsBindingObserver {
  SyncBloc({
    required SynchronizationRepository repository,
    required SyncConnectivityMonitor connectivityMonitor,
  }) : _repository = repository,
       _connectivityMonitor = connectivityMonitor,
       super(const SyncState()) {
    WidgetsBinding.instance.addObserver(this);
    on<SyncInitialized>(_onInitialized);
    on<SyncRequested>(_onSyncRequested);
    on<SyncConnectivityChanged>(_onConnectivityChanged);

    _connectivitySubscription = _connectivityMonitor.connectionChanges.listen((
      hasNetwork,
    ) {
      if (!isClosed) add(SyncConnectivityChanged(hasNetwork));
    });
    add(const SyncInitialized());
  }

  final SynchronizationRepository _repository;
  final SyncConnectivityMonitor _connectivityMonitor;
  late final StreamSubscription<bool> _connectivitySubscription;
  Timer? _retryTimer;
  bool _synchronizationInProgress = false;
  bool _syncAgainWhenIdle = false;

  Future<void> _onInitialized(
    SyncInitialized event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(status: SyncStatus.checking));
    try {
      final stats = await _repository.getQueueStats();
      final hasNetwork = await _connectivityMonitor.hasNetworkConnection();
      emit(
        state.copyWith(
          status: hasNetwork ? SyncStatus.idle : SyncStatus.offline,
          hasNetwork: hasNetwork,
          pendingCount: stats.pendingCount,
          failedCount: stats.failedCount,
          syncedCount: stats.syncedCount,
          lastSyncAt: stats.lastSyncAt ?? state.lastSyncAt,
        ),
      );
      if (hasNetwork) await _synchronize(emit);
    } catch (_) {
      emit(
        state.copyWith(
          status: SyncStatus.failure,
          message: 'Could not load synchronization status.',
        ),
      );
    }
  }

  Future<void> _onSyncRequested(SyncRequested event, Emitter<SyncState> emit) =>
      _synchronize(emit);

  Future<void> _onConnectivityChanged(
    SyncConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      state.copyWith(
        hasNetwork: event.hasNetwork,
        status: !event.hasNetwork && !_synchronizationInProgress
            ? SyncStatus.offline
            : state.status,
      ),
    );
    if (event.hasNetwork) await _synchronize(emit);
  }

  Future<void> _synchronize(Emitter<SyncState> emit) async {
    if (_synchronizationInProgress) {
      _syncAgainWhenIdle = true;
      return;
    }
    _synchronizationInProgress = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      final hasNetwork = await _connectivityMonitor.hasNetworkConnection();
      if (!hasNetwork) {
        final stats = await _repository.getQueueStats();
        emit(
          state.copyWith(
            status: SyncStatus.offline,
            hasNetwork: false,
            pendingCount: stats.pendingCount,
            failedCount: stats.failedCount,
            syncedCount: stats.syncedCount,
            clearMessage: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: SyncStatus.syncing,
          hasNetwork: true,
          acceptedThisRun: 0,
          duplicatesThisRun: 0,
          clearMessage: true,
        ),
      );
      final report = await _repository.synchronizePendingRecords();
      final nextState = _stateForReport(report);
      emit(nextState);
      _scheduleRetry(nextState.nextRetryAt);
    } catch (_) {
      emit(
        state.copyWith(
          status: SyncStatus.failure,
          message:
              'Synchronization failed. Saved records remain on this device.',
        ),
      );
      try {
        final stats = await _repository.getQueueStats();
        emit(
          state.copyWith(
            pendingCount: stats.pendingCount,
            failedCount: stats.failedCount,
            syncedCount: stats.syncedCount,
          ),
        );
      } catch (_) {
        // Keep the last displayed queue totals if local storage is unavailable.
      }
    } finally {
      _synchronizationInProgress = false;
      if (_syncAgainWhenIdle && !isClosed) {
        _syncAgainWhenIdle = false;
        add(const SyncRequested());
      }
    }
  }

  SyncState _stateForReport(SyncReport report) {
    final status = switch (report.outcome) {
      SyncOutcome.completed => SyncStatus.completed,
      SyncOutcome.backendUnavailable => SyncStatus.backendUnavailable,
      SyncOutcome.notConfigured => SyncStatus.notConfigured,
      SyncOutcome.authenticationRequired => SyncStatus.authenticationRequired,
      SyncOutcome.retryScheduled => SyncStatus.retryScheduled,
      SyncOutcome.failed => SyncStatus.failure,
    };
    return state.copyWith(
      status: status,
      pendingCount: report.queue.pendingCount,
      failedCount: report.queue.failedCount,
      syncedCount: report.queue.syncedCount,
      acceptedThisRun: report.acceptedCount,
      duplicatesThisRun: report.duplicateCount,
      lastSyncAt: report.completedAt ?? state.lastSyncAt,
      nextRetryAt: report.queue.nextRetryAt,
      clearNextRetryAt: report.queue.nextRetryAt == null,
      message:
          report.message ??
          (report.rejectedCount > 0
              ? 'Some records were rejected and remain in the failed queue.'
              : null),
      clearMessage: report.message == null && report.rejectedCount == 0,
    );
  }

  void _scheduleRetry(DateTime? nextRetryAt) {
    _retryTimer?.cancel();
    if (nextRetryAt == null || isClosed) return;
    final delay = nextRetryAt.difference(DateTime.now().toUtc());
    _retryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!isClosed) add(const SyncRequested());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isClosed) {
      add(const SyncRequested());
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    await _connectivitySubscription.cancel();
    await super.close();
  }
}
