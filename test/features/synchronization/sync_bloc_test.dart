import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trailsync/features/synchronization/domain/entities/sync_queue_stats.dart';
import 'package:trailsync/features/synchronization/domain/entities/sync_report.dart';
import 'package:trailsync/features/synchronization/domain/repositories/synchronization_repository.dart';
import 'package:trailsync/features/synchronization/domain/services/sync_connectivity_monitor.dart';
import 'package:trailsync/features/synchronization/presentation/bloc/sync_bloc.dart';
import 'package:trailsync/features/synchronization/presentation/bloc/sync_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connectivity restoration triggers synchronization', () async {
    final monitor = TestConnectivityMonitor();
    final repository = TestSynchronizationRepository();
    final bloc = SyncBloc(repository: repository, connectivityMonitor: monitor);
    final offlineState = bloc.stream.firstWhere(
      (state) => state.status == SyncStatus.offline,
    );

    expect(
      (await offlineState.timeout(const Duration(seconds: 2))).hasNetwork,
      isFalse,
    );
    final completedState = bloc.stream.firstWhere(
      (state) => state.status == SyncStatus.completed,
    );
    monitor.update(true);

    final state = await completedState.timeout(const Duration(seconds: 2));
    expect(state.hasNetwork, isTrue);
    expect(state.pendingCount, 0);
    expect(repository.synchronizationCount, 1);
    await bloc.close();
    await monitor.close();
  });
}

class TestConnectivityMonitor implements SyncConnectivityMonitor {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _hasNetwork = false;

  @override
  Future<bool> hasNetworkConnection() async => _hasNetwork;

  @override
  Stream<bool> get connectionChanges => _controller.stream;

  void update(bool value) {
    _hasNetwork = value;
    _controller.add(value);
  }

  Future<void> close() => _controller.close();
}

class TestSynchronizationRepository implements SynchronizationRepository {
  int synchronizationCount = 0;

  @override
  Future<SyncQueueStats> getQueueStats() async =>
      const SyncQueueStats(pendingCount: 2, failedCount: 0, syncedCount: 0);

  @override
  Future<SyncReport> synchronizePendingRecords() async {
    synchronizationCount++;
    return SyncReport(
      outcome: SyncOutcome.completed,
      acceptedCount: 2,
      queue: const SyncQueueStats(
        pendingCount: 0,
        failedCount: 0,
        syncedCount: 2,
      ),
      completedAt: DateTime.utc(2026),
    );
  }
}
