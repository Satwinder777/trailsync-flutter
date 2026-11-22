import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
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
          final isOffline = state.hasNetwork == false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SyncStatusIcon(
                          offline: isOffline,
                          syncing: state.isSyncing,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusLabel(state.status),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                isOffline
                                    ? 'Your routes are safe on this device and will wait for a connection.'
                                    : 'Saved GPS records upload in batches and stay local until acknowledged.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (state.message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Text(state.message!),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isSyncing
                            ? null
                            : () => bloc.add(const SyncRequested()),
                        icon: state.isSyncing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          state.isSyncing ? 'Syncing routes…' : 'Sync now',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'On this device',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Each point remains here until the server confirms it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final cards = [
                    _QueueMetric(
                      label: 'Pending',
                      count: state.pendingCount,
                      icon: Icons.cloud_upload_outlined,
                      tone: AppColors.amber,
                    ),
                    _QueueMetric(
                      label: 'Acknowledged',
                      count: state.syncedCount,
                      icon: Icons.cloud_done_outlined,
                      tone: AppColors.forest,
                    ),
                    _QueueMetric(
                      label: 'Failed',
                      count: state.failedCount,
                      icon: Icons.error_outline,
                      tone: AppColors.danger,
                    ),
                  ];
                  if (compact) {
                    return Column(
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          cards[index],
                          if (index != cards.length - 1)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        Expanded(child: cards[index]),
                        if (index != cards.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
              if (state.acceptedThisRun > 0 || state.duplicatesThisRun > 0) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest sync result',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ResultRow(
                        label: 'New records accepted',
                        count: state.acceptedThisRun,
                      ),
                      _ResultRow(
                        label: 'Already received safely',
                        count: state.duplicatesThisRun,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.forest),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.lastSyncAt == null
                            ? 'No successful sync recorded yet'
                            : 'Last sync attempt · ${_formatTime(state.lastSyncAt!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
    SyncStatus.checking => 'Checking sync status…',
    SyncStatus.offline => 'Waiting for a connection',
    SyncStatus.idle => 'Ready to synchronize',
    SyncStatus.syncing => 'Synchronizing saved trails…',
    SyncStatus.completed => 'Your trails are up to date',
    SyncStatus.retryScheduled => 'A retry is scheduled',
    SyncStatus.backendUnavailable => 'Sync service is unavailable',
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

class _SyncStatusIcon extends StatelessWidget {
  const _SyncStatusIcon({required this.offline, required this.syncing});

  final bool offline;
  final bool syncing;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: offline
          ? AppColors.canvas
          : AppColors.accent.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(16),
    ),
    child: SizedBox(
      width: 50,
      height: 50,
      child: Icon(
        offline
            ? Icons.cloud_off_outlined
            : syncing
            ? Icons.sync
            : Icons.cloud_done_outlined,
        color: AppColors.forest,
      ),
    ),
  );
}

class _QueueMetric extends StatelessWidget {
  const _QueueMetric({
    required this.label,
    required this.count,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(icon, color: tone),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(count.toString(), style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}
