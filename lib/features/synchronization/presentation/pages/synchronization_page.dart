import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_page_scaffold.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

class SynchronizationPage extends StatelessWidget {
  const SynchronizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Synchronization',
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          final bloc = context.read<SyncBloc>();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.hasNetwork == true
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusLabel(state.status),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (state.isSyncing)
                          const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    if (state.message != null) ...[
                      const SizedBox(height: 10),
                      Text(state.message!),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isSyncing
                            ? null
                            : () => bloc.add(const SyncRequested()),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync now'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'On this device',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _QueueCount(label: 'Pending', count: state.pendingCount),
                    _QueueCount(label: 'Failed', count: state.failedCount),
                    _QueueCount(
                      label: 'Acknowledged',
                      count: state.syncedCount,
                    ),
                    if (state.acceptedThisRun > 0 ||
                        state.duplicatesThisRun > 0) ...[
                      const Divider(height: 24),
                      Text('Accepted this run: ${state.acceptedThisRun}'),
                      Text('Already received: ${state.duplicatesThisRun}'),
                    ],
                    if (state.lastSyncAt != null) ...[
                      const SizedBox(height: 12),
                      Text('Last attempt: ${_formatTime(state.lastSyncAt!)}'),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Location records stay in local storage until the server '
                      'acknowledges them.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(SyncStatus status) => switch (status) {
    SyncStatus.checking => 'Checking synchronization status…',
    SyncStatus.offline => 'Offline',
    SyncStatus.idle => 'Ready to synchronize',
    SyncStatus.syncing => 'Synchronizing saved trails…',
    SyncStatus.completed => 'Synchronization complete',
    SyncStatus.retryScheduled => 'Retry scheduled',
    SyncStatus.backendUnavailable => 'Backend unavailable',
    SyncStatus.notConfigured => 'Backend configuration needed',
    SyncStatus.authenticationRequired => 'Sign in to synchronize',
    SyncStatus.failure => 'Synchronization needs attention',
  };

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class _QueueCount extends StatelessWidget {
  const _QueueCount({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(count.toString(), style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}
