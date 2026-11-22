import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_empty_state.dart';
import '../../../../core/design_system/widgets/app_metric_card.dart';
import '../../../../core/design_system/widgets/app_page_scaffold.dart';
import '../../../../features/tracking/domain/entities/location_record.dart';
import '../../../../features/tracking/domain/entities/tracking_session.dart';
import '../../../../features/tracking/domain/entities/tracking_summary.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';

class HistorySessionDetailsPage extends StatefulWidget {
  const HistorySessionDetailsPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  State<HistorySessionDetailsPage> createState() =>
      _HistorySessionDetailsPageState();
}

class _HistorySessionDetailsPageState extends State<HistorySessionDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(
      HistorySessionDetailsRequested(widget.sessionId),
    );
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Trail details',
    body: BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (previous, current) =>
          previous.detailStatus != current.detailStatus ||
          previous.selectedSession != current.selectedSession ||
          previous.recordSummary != current.recordSummary ||
          previous.records != current.records ||
          previous.hasMoreRecords != current.hasMoreRecords ||
          previous.isLoadingMoreRecords != current.isLoadingMoreRecords ||
          previous.detailMessage != current.detailMessage,
      builder: (context, state) {
        if (state.detailStatus == HistoryDetailStatus.loading ||
            state.detailStatus == HistoryDetailStatus.idle) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.detailStatus == HistoryDetailStatus.failure) {
          return _DetailsFailure(
            message: state.detailMessage ?? 'Trail details are unavailable.',
            onRetry: () => context.read<HistoryBloc>().add(
              HistorySessionDetailsRequested(widget.sessionId),
            ),
          );
        }
        final session = state.selectedSession;
        final summary = state.recordSummary;
        if (session == null || summary == null) {
          return const AppEmptyState(
            icon: Icons.route_outlined,
            title: 'Trail unavailable',
            message: 'This saved session could not be found on this device.',
          );
        }
        return _DetailsBody(
          session: session,
          summary: summary,
          records: state.records,
          hasMoreRecords: state.hasMoreRecords,
          isLoadingMoreRecords: state.isLoadingMoreRecords,
          onLoadMore: () => context.read<HistoryBloc>().add(
            const HistoryMoreRecordsRequested(),
          ),
          detailMessage: state.detailMessage,
          sessionId: widget.sessionId,
        );
      },
    ),
  );
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.session,
    required this.summary,
    required this.records,
    required this.hasMoreRecords,
    required this.isLoadingMoreRecords,
    required this.onLoadMore,
    required this.detailMessage,
    required this.sessionId,
  });

  final TrackingSession session;
  final SessionRecordSummary summary;
  final List<LocationRecord> records;
  final bool hasMoreRecords;
  final bool isLoadingMoreRecords;
  final VoidCallback onLoadMore;
  final String? detailMessage;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final endedAt = session.endedAt ?? DateTime.now().toUtc();
    final duration = endedAt.difference(session.startedAt);
    final metrics = [
      AppMetricCard(
        label: 'Distance',
        value: _formatDistance(session.distanceMeters),
        icon: Icons.straighten,
      ),
      AppMetricCard(
        label: 'Duration',
        value: _formatDuration(duration),
        icon: Icons.timer_outlined,
      ),
      AppMetricCard(
        label: 'GPS records',
        value: summary.recordCount.toString(),
        icon: Icons.place_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760 ? 3 : 1;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title?.trim().isNotEmpty == true
                        ? session.title!
                        : _formatDate(session.startedAt),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatDate(session.startedAt)} – '
                    '${session.endedAt == null ? 'In progress' : _formatDate(endedAt)}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SessionStatusChip(status: session.status),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(
                      '${AppRoutePaths.map}?sessionId=$sessionId',
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View route on map'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (columns == 1)
              ...metrics.expand(
                (metric) => [metric, const SizedBox(height: AppSpacing.sm)],
              )
            else
              GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 166,
                children: metrics,
              ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synchronization',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SyncCountRow(label: 'Synced', count: summary.syncedCount),
                  _SyncCountRow(
                    label: 'Pending or retrying',
                    count: summary.pendingCount + summary.retryCount,
                  ),
                  _SyncCountRow(
                    label: 'Uploading',
                    count: summary.syncingCount,
                  ),
                  _SyncCountRow(label: 'Failed', count: summary.failedCount),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Route records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (records.isEmpty)
              const AppCard(
                child: Text('This session has no accepted GPS records.'),
              )
            else
              ...records.map((record) => _LocationRecordTile(record: record)),
            if (detailMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(detailMessage!),
            ],
            if (hasMoreRecords)
              Center(
                child: isLoadingMoreRecords
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      )
                    : TextButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Load older records'),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _LocationRecordTile extends StatelessWidget {
  const _LocationRecordTile({required this.record});

  final LocationRecord record;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(record.recordedAt)),
                Text(
                  '${record.latitude.toStringAsFixed(5)}, '
                  '${record.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _RecordSyncChip(status: record.syncStatus),
        ],
      ),
    ),
  );
}

class _SessionStatusChip extends StatelessWidget {
  const _SessionStatusChip({required this.status});

  final TrackingSessionStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(switch (status) {
      TrackingSessionStatus.recording => 'Recording',
      TrackingSessionStatus.paused => 'Paused',
      TrackingSessionStatus.completed => 'Completed',
      TrackingSessionStatus.cancelled => 'Cancelled',
    }),
    visualDensity: VisualDensity.compact,
  );
}

class _RecordSyncChip extends StatelessWidget {
  const _RecordSyncChip({required this.status});

  final LocationSyncStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(switch (status) {
      LocationSyncStatus.pending => 'Pending',
      LocationSyncStatus.syncing => 'Syncing',
      LocationSyncStatus.retry => 'Retry',
      LocationSyncStatus.synced => 'Synced',
      LocationSyncStatus.failed => 'Failed',
    }),
    visualDensity: VisualDensity.compact,
  );
}

class _SyncCountRow extends StatelessWidget {
  const _SyncCountRow({required this.label, required this.count});

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

class _DetailsFailure extends StatelessWidget {
  const _DetailsFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatDistance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(2)} km'
    : '${meters.toStringAsFixed(0)} m';

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
}
